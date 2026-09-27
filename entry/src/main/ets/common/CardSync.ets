import { formBindingData, formProvider } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CountdownEvent, daysBetween } from '../model/CountdownEvent';

const STORE_NAME = 'daysmatter_store';
const KEY_FORM_IDS = 'form_ids';

/**
 * 卡片数据同步：主应用数据变化后，把最近事件推送到所有已添加的桌面卡片
 */
export class CardSync {
  static async updateAllCards(context: common.Context, events: CountdownEvent[]): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, STORE_NAME);
      const raw = await pref.get(KEY_FORM_IDS, '[]') as string;
      const formIds = JSON.parse(raw) as string[];
      if (formIds.length === 0) {
        return;
      }
      const binding: Record<string, string> = CardSync.buildPayload(events);
      for (const formId of formIds) {
        try {
          await formProvider.updateForm(formId, formBindingData.createFormBindingData(binding));
        } catch (err) {
          // 卡片可能已被移除，忽略单个失败
        }
      }
    } catch (err) {
      // Previewer / 无卡片环境静默
    }
  }

  private static buildPayload(events: CountdownEvent[]): Record<string, string> {
    const payload: Record<string, string> = {
      'eventName': '暂无事件',
      'daysText': '--'
    };
    // 取最近一个未过期事件；全过期则取日期最近的一个
    const now = Date.now();
    let chosen: CountdownEvent | undefined = events.find((e: CountdownEvent) => daysBetween(e.targetDate) >= 0);
    if (!chosen && events.length > 0) {
      chosen = events[events.length - 1];
    }
    if (chosen) {
      payload['eventName'] = chosen.name;
      const d = daysBetween(chosen.targetDate);
      if (d === 0) {
        payload['daysText'] = '今天';
      } else if (d < 0) {
        payload['daysText'] = `已过 ${-d} 天`;
      } else {
        payload['daysText'] = `${d} 天`;
      }
    }
    return payload;
  }
}
