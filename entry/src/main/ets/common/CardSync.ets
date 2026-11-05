import { formBindingData, formProvider } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CountdownEvent, daysToEvent, effectiveDate, categoryOption } from '../model/CountdownEvent';

const STORE_NAME = 'daysmatter_store';
const KEY_FORM_IDS = 'form_ids';
const KEY_FORM_DIMS = 'form_dims';
const TAG = 'CardSync';
const DOMAIN = 0x0000;

/**
 * 卡片单行数据（2×4 卡片最多展示 3 条）
 */
export interface CardRow {
  name: string;
  daysText: string;
  emoji: string;
}

/**
 * 卡片数据同步：主应用数据变化后，把最近事件推送到所有已添加的桌面卡片
 */
export class CardSync {
  static async updateAllCards(context: common.Context, events: CountdownEvent[]): Promise<void> {
    try {
      // 与 EventStore 保持一致：统一用 ApplicationContext（应用级目录）
      const pref = await preferences.getPreferences(context.getApplicationContext(), STORE_NAME);
      const raw = await pref.get(KEY_FORM_IDS, '[]') as string;
      const formIds = JSON.parse(raw) as string[];
      if (formIds.length === 0) {
        hilog.info(DOMAIN, TAG, 'updateAllCards: no registered forms');
        return;
      }
      const rawDims = await pref.get(KEY_FORM_DIMS, '{}') as string;
      const dims = JSON.parse(rawDims) as Record<string, number>;
      hilog.info(DOMAIN, TAG, 'updateAllCards: push to %{public}d forms', formIds.length);
      for (const formId of formIds) {
        try {
          const binding = CardSync.buildPayload(events);
          const dim = dims[formId];
          binding['wide'] = dim !== undefined && dim >= 3 ? '1' : '0';
          await formProvider.updateForm(formId, formBindingData.createFormBindingData(binding));
        } catch (err) {
          // 卡片可能已被移除，忽略单个失败
          hilog.error(DOMAIN, TAG, 'updateForm %{public}s failed: %{public}s', formId, (err as Error).message);
        }
      }
    } catch (err) {
      // Previewer / 无卡片环境静默
      hilog.error(DOMAIN, TAG, 'updateAllCards failed: %{public}s', (err as Error).message);
    }
  }

  /**
   * 组装卡片数据：置顶优先，其次按剩余天数升序
   */
  public static buildPayload(events: CountdownEvent[]): Record<string, string> {
    const payload: Record<string, string> = {
      'eventName': '暂无事件',
      'daysText': '--',
      'dateText': '去应用里添加一个日子',
      'itemsJson': '[]',
      'count': '0',
      'wide': '0'
    };
    if (events.length === 0) {
      return payload;
    }
    const sorted = events.slice();
    sorted.sort((a: CountdownEvent, b: CountdownEvent) => {
      if (a.pinned !== b.pinned) {
        return a.pinned ? -1 : 1;
      }
      return daysToEvent(a) - daysToEvent(b);
    });

    const first = sorted[0];
    payload['eventName'] = first.name;
    payload['daysText'] = CardSync.daysLabel(daysToEvent(first));
    payload['dateText'] = CardSync.dateLabel(first);
    payload['count'] = `${events.length}`;

    const rows: CardRow[] = [];
    const limit = Math.min(sorted.length, 3);
    for (let i = 0; i < limit; i++) {
      const e = sorted[i];
      const row: CardRow = {
        name: e.name,
        daysText: CardSync.daysLabel(daysToEvent(e)),
        emoji: categoryOption(e.category).emoji
      };
      rows.push(row);
    }
    payload['itemsJson'] = JSON.stringify(rows);
    return payload;
  }

  private static daysLabel(days: number): string {
    if (days === 0) {
      return '今天';
    }
    if (days < 0) {
      return `已过 ${-days} 天`;
    }
    return `${days} 天`;
  }

  private static dateLabel(item: CountdownEvent): string {
    const d = effectiveDate(item);
    if (item.repeatYearly) {
      return `每年 ${d.substring(5)}`;
    }
    return d;
  }
}
