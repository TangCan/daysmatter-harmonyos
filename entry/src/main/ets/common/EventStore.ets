import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CountdownEvent } from '../model/CountdownEvent';
import { PinVerifyResult, hashPin, randomSalt, verifyPin } from './PinLock';

const STORE_NAME = 'daysmatter_store';
const KEY_EVENTS = 'events_json';
const KEY_PRIVACY = 'privacy_agreed';
const KEY_LOCK_ENABLED = 'lock_enabled';
const KEY_LOCK_HASH = 'lock_hash';
const KEY_LOCK_SALT = 'lock_salt';
// 1.3.2 及更早版本存的明文 PIN，仅用于老用户迁移，迁移后即清空
const KEY_LOCK_PIN_LEGACY = 'lock_pin';

/**
 * 事件持久化：使用 Preferences 存 JSON 数组（MVP 够用，后期可升级 relationalStore）
 */
export class EventStore {
  // 关键：统一用 ApplicationContext（应用级目录），
  // 否则 UIAbility 和 FormExtensionAbility 各自的 context 可能解析到不同目录，
  // 导致主应用写的事件、卡片侧读不到（桌面卡片永远"暂无事件"）
  static async load(context: common.Context): Promise<CountdownEvent[]> {
    try {
      const pref = await preferences.getPreferences(context.getApplicationContext(), STORE_NAME);
      const raw = await pref.get(KEY_EVENTS, '[]') as string;
      const list = JSON.parse(raw) as CountdownEvent[];
      return list.map((o: CountdownEvent) => CountdownEvent.fromJson(o));
    } catch (err) {
      // Previewer 等无持久化环境下降级为空列表
      return [];
    }
  }

  // 同步版本：onAddForm 必须同步返回卡片初始数据（卡片选择器预览只认返回值），
  // 异步推送只对添加后的实体卡片生效
  static loadSync(context: common.Context): CountdownEvent[] {
    try {
      const pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
      const raw = pref.getSync(KEY_EVENTS, '[]') as string;
      const list = JSON.parse(raw) as CountdownEvent[];
      return list.map((o: CountdownEvent) => CountdownEvent.fromJson(o));
    } catch (err) {
      return [];
    }
  }

  static async save(context: common.Context, events: CountdownEvent[]): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context.getApplicationContext(), STORE_NAME);
      await pref.put(KEY_EVENTS, JSON.stringify(events));
      await pref.flush();
    } catch (err) {
      // 静默失败：Previewer 环境不支持持久化
    }
  }

  /**
   * 是否已同意隐私政策（首次启动必须弹窗确认，合规要求）
   */
  static isPrivacyAgreed(context: common.Context): boolean {
    try {
      const pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
      return pref.getSync(KEY_PRIVACY, false) as boolean;
    } catch (err) {
      return false;
    }
  }

  static setPrivacyAgreed(context: common.Context, agreed: boolean): void {
    try {
      preferences.getPreferences(context.getApplicationContext(), STORE_NAME).then(async (pref) => {
        await pref.put(KEY_PRIVACY, agreed);
        await pref.flush();
      }).catch((err: Error) => {
        // 写入失败不阻断使用，下次启动会再次询问
      });
    } catch (err) {
      // 静默
    }
  }

  // ---------- 隐私锁（4 位数字 PIN，纯本地） ----------
  // 安全约定：只保存「随机盐 + 加盐 SHA-256 摘要」，不在本地明文保存 PIN
  static isLockEnabled(context: common.Context): boolean {
    try {
      const pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
      return pref.getSync(KEY_LOCK_ENABLED, false) as boolean;
    } catch (err) {
      return false;
    }
  }

  static getLockHash(context: common.Context): string {
    try {
      const pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
      return pref.getSync(KEY_LOCK_HASH, '') as string;
    } catch (err) {
      return '';
    }
  }

  static getLockSalt(context: common.Context): string {
    try {
      const pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
      return pref.getSync(KEY_LOCK_SALT, '') as string;
    } catch (err) {
      return '';
    }
  }

  /**
   * 旧版明文 PIN（仅用于迁移，1.3.3 起不再写入）
   */
  static getLegacyPin(context: common.Context): string {
    try {
      const pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
      return pref.getSync(KEY_LOCK_PIN_LEGACY, '') as string;
    } catch (err) {
      return '';
    }
  }

  /**
   * 设置 / 修改 PIN：写入加盐摘要并清除明文
   */
  static async saveLockPin(context: common.Context, pin: string): Promise<void> {
    try {
      const salt = randomSalt();
      const hash = hashPin(pin, salt);
      const pref = await preferences.getPreferences(context.getApplicationContext(), STORE_NAME);
      await pref.put(KEY_LOCK_ENABLED, true);
      await pref.put(KEY_LOCK_SALT, salt);
      await pref.put(KEY_LOCK_HASH, hash);
      await pref.put(KEY_LOCK_PIN_LEGACY, '');
      await pref.flush();
    } catch (err) {
      // 静默：写入失败时上层按"未开启"处理
    }
  }

  /**
   * 关闭隐私锁并清除全部锁数据
   */
  static async disableLock(context: common.Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context.getApplicationContext(), STORE_NAME);
      await pref.put(KEY_LOCK_ENABLED, false);
      await pref.put(KEY_LOCK_SALT, '');
      await pref.put(KEY_LOCK_HASH, '');
      await pref.put(KEY_LOCK_PIN_LEGACY, '');
      await pref.flush();
    } catch (err) {
      // 静默
    }
  }

  /**
   * 校验 PIN；若命中旧版明文 PIN，则自动升级为加盐摘要存储
   */
  static verifyLockPin(context: common.Context, pin: string): PinVerifyResult {
    const hash = EventStore.getLockHash(context);
    const salt = EventStore.getLockSalt(context);
    if (hash.length > 0) {
      const result: PinVerifyResult = { ok: verifyPin(pin, salt, hash), legacy: false };
      return result;
    }
    const legacy = EventStore.getLegacyPin(context);
    if (legacy.length > 0 && legacy === pin) {
      // 透明迁移：成功后立刻改存摘要，明文不再落盘
      EventStore.saveLockPin(context, pin).catch((err: Error) => {
        // 迁移失败不影响本次校验结果，下次成功解锁时再试
      });
      const migrated: PinVerifyResult = { ok: true, legacy: true };
      return migrated;
    }
    const failed: PinVerifyResult = { ok: false, legacy: legacy.length > 0 };
    return failed;
  }
}
