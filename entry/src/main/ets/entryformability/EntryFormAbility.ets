import { Want } from '@kit.AbilityKit';
import { formBindingData, formProvider, FormExtensionAbility } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { EventStore } from '../common/EventStore';
import { CardSync } from '../common/CardSync';

const TAG = 'EntryFormAbility';
const STORE_NAME = 'daysmatter_store';
const KEY_FORM_IDS = 'form_ids';
const DOMAIN = 0x0000;

/**
 * 桌面卡片生命周期：添加时登记 formId（供主应用推送数据），销毁时移除
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN, TAG, 'onAddForm');
    const parameters = want.parameters;
    let formId: string = '';
    if (parameters) {
      formId = parameters['ohos.extra.param.key_form_identity'] as string;
    }
    if (formId && formId.length > 0) {
      this.registerFormId(formId);
    }
    // 先返回占位数据；registerFormId 完成后会立即把当前最新事件推送到这张新卡片
    const binding: Record<string, string> = {
      'eventName': '暂无事件',
      'daysText': '--'
    };
    return formBindingData.createFormBindingData(binding);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN, TAG, 'onUpdateForm, formId=%{public}s', formId);
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN, TAG, 'onRemoveForm, formId=%{public}s', formId);
    this.unregisterFormId(formId);
  }

  private registerFormId(formId: string): void {
    preferences.getPreferences(this.context, STORE_NAME).then(async (pref) => {
      const raw = await pref.get(KEY_FORM_IDS, '[]') as string;
      const ids: string[] = JSON.parse(raw) as string[];
      if (!ids.includes(formId)) {
        ids.push(formId);
        await pref.put(KEY_FORM_IDS, JSON.stringify(ids));
        await pref.flush();
      }
      // 修复：新添加的卡片立即推送当前最新事件，否则"先加事件后加卡片"时卡片永远为空
      try {
        const events = await EventStore.load(this.context);
        const binding = CardSync.buildPayload(events);
        await formProvider.updateForm(formId, formBindingData.createFormBindingData(binding));
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'push initial form data failed: %{public}s', (err as Error).message);
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'registerFormId failed: %{public}s', err.message);
    });
  }

  private unregisterFormId(formId: string): void {
    preferences.getPreferences(this.context, STORE_NAME).then(async (pref) => {
      const raw = await pref.get(KEY_FORM_IDS, '[]') as string;
      const ids = (JSON.parse(raw) as string[]).filter((id: string) => id !== formId);
      pref.put(KEY_FORM_IDS, JSON.stringify(ids));
      pref.flush();
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'unregisterFormId failed: %{public}s', err.message);
    });
  }
}
