import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CountdownEvent } from '../model/CountdownEvent';

const STORE_NAME = 'daysmatter_store';
const KEY_EVENTS = 'events_json';

/**
 * 事件持久化：使用 Preferences 存 JSON 数组（MVP 够用，后期可升级 relationalStore）
 */
export class EventStore {
  static async load(context: common.Context): Promise<CountdownEvent[]> {
    try {
      const pref = await preferences.getPreferences(context, STORE_NAME);
      const raw = await pref.get(KEY_EVENTS, '[]') as string;
      const list = JSON.parse(raw) as CountdownEvent[];
      return list.map((o: CountdownEvent) => CountdownEvent.fromJson(o));
    } catch (err) {
      // Previewer 等无持久化环境下降级为空列表
      return [];
    }
  }

  static async save(context: common.Context, events: CountdownEvent[]): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, STORE_NAME);
      await pref.put(KEY_EVENTS, JSON.stringify(events));
      await pref.flush();
    } catch (err) {
      // 静默失败：Previewer 环境不支持持久化
    }
  }
}
