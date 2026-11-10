import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { EventStore } from '../main/ets/common/EventStore';
import { CountdownEvent } from '../main/ets/model/CountdownEvent';
import { mock, resetMock, tick, fakeContext, brokenContext } from './helpers/Harness';

const STORE = 'daysmatter_store';
const KEY_EVENTS = 'events_json';

function seedRawStore(raw: string): void {
  let store = mock.prefs.get(STORE);
  if (store === undefined) {
    store = new Map<string, Object>();
    mock.prefs.set(STORE, store);
  }
  store.set(KEY_EVENTS, raw);
}

function seedKey(key: string, value: Object): void {
  let store = mock.prefs.get(STORE);
  if (store === undefined) {
    store = new Map<string, Object>();
    mock.prefs.set(STORE, store);
  }
  store.set(key, value);
}

function sampleEvent(id: string, name: string): CountdownEvent {
  const e = new CountdownEvent();
  e.id = id;
  e.name = name;
  e.targetDate = '2030-01-01';
  e.category = 'birthday';
  e.repeatYearly = true;
  return e;
}

export default function eventStoreTest() {
  describe('EventStore.事件读写', () => {
    beforeEach(() => {
      resetMock();
    });

    it('保存后可异步读回', 0, async () => {
      const ctx = fakeContext();
      await EventStore.save(ctx, [sampleEvent('1', '生日')]);
      const list = await EventStore.load(ctx);
      expect(list.length).assertEqual(1);
      expect(list[0].name).assertEqual('生日');
      expect(list[0].category).assertEqual('birthday');
      expect(list[0].repeatYearly).assertTrue();
    });

    it('保存后可同步读回', 0, async () => {
      const ctx = fakeContext();
      await EventStore.save(ctx, [sampleEvent('1', '生日')]);
      const list = EventStore.loadSync(ctx);
      expect(list.length).assertEqual(1);
      expect(list[0].id).assertEqual('1');
    });

    it('空存储返回空数组', 0, async () => {
      const ctx = fakeContext();
      expect((await EventStore.load(ctx)).length).assertEqual(0);
      expect(EventStore.loadSync(ctx).length).assertEqual(0);
    });

    it('存储内容损坏时降级为空数组', 0, async () => {
      const ctx = fakeContext();
      seedRawStore('not-a-json');
      expect((await EventStore.load(ctx)).length).assertEqual(0);
      expect(EventStore.loadSync(ctx).length).assertEqual(0);
    });

    it('上下文不可用时读操作降级为空数组', 0, async () => {
      const ctx = brokenContext();
      expect((await EventStore.load(ctx)).length).assertEqual(0);
      expect(EventStore.loadSync(ctx).length).assertEqual(0);
    });

    it('取不到 Preferences 时读操作降级', 0, async () => {
      const ctx = fakeContext();
      mock.fail.getPreferences = true;
      expect((await EventStore.load(ctx)).length).assertEqual(0);
      mock.fail.getPreferences = false;
      mock.fail.getPreferencesSync = true;
      expect(EventStore.loadSync(ctx).length).assertEqual(0);
    });

    it('写入失败不抛异常（静默降级）', 0, async () => {
      const ctx = fakeContext();
      mock.fail.put = true;
      await EventStore.save(ctx, [sampleEvent('1', '生日')]);
      mock.fail.put = false;
      mock.fail.flush = true;
      await EventStore.save(ctx, [sampleEvent('1', '生日')]);
      expect(true).assertTrue();
    });

    it('上下文不可用时写操作不抛异常', 0, async () => {
      await EventStore.save(brokenContext(), [sampleEvent('1', '生日')]);
      expect(true).assertTrue();
    });
  });

  describe('EventStore.隐私同意状态', () => {
    beforeEach(() => {
      resetMock();
    });

    it('默认未同意', 0, () => {
      expect(EventStore.isPrivacyAgreed(fakeContext())).assertFalse();
    });

    it('同意后可读回 true', 0, async () => {
      const ctx = fakeContext();
      EventStore.setPrivacyAgreed(ctx, true);
      await tick();
      expect(EventStore.isPrivacyAgreed(ctx)).assertTrue();
      expect(mock.prefFlushCount).assertLarger(0);
    });

    it('上下文不可用时视为未同意', 0, () => {
      expect(EventStore.isPrivacyAgreed(brokenContext())).assertFalse();
    });

    it('写入失败不抛异常', 0, async () => {
      mock.fail.put = true;
      EventStore.setPrivacyAgreed(fakeContext(), true);
      await tick();
      expect(true).assertTrue();
    });

    it('取 Preferences 抛错时静默', 0, async () => {
      mock.fail.getPreferences = true;
      EventStore.setPrivacyAgreed(fakeContext(), true);
      await tick();
      expect(true).assertTrue();
    });

    it('环境完全不支持 Preferences 时静默', 0, async () => {
      mock.fail.getPreferencesThrowSync = true;
      EventStore.setPrivacyAgreed(fakeContext(), true);
      await tick();
      mock.fail.getPreferencesThrowSync = false;
      expect(mock.prefFlushCount).assertEqual(0);
    });
  });

  describe('EventStore.隐私锁', () => {
    beforeEach(() => {
      resetMock();
    });

    it('默认关闭且无凭证', 0, () => {
      const ctx = fakeContext();
      expect(EventStore.isLockEnabled(ctx)).assertFalse();
      expect(EventStore.getLockHash(ctx)).assertEqual('');
      expect(EventStore.getLockSalt(ctx)).assertEqual('');
      expect(EventStore.getLegacyPin(ctx)).assertEqual('');
    });

    it('设置 PIN 后只保存加盐摘要，不落明文', 0, async () => {
      const ctx = fakeContext();
      await EventStore.saveLockPin(ctx, '1234');
      expect(EventStore.isLockEnabled(ctx)).assertTrue();
      const hash = EventStore.getLockHash(ctx);
      const salt = EventStore.getLockSalt(ctx);
      expect(/^[0-9a-f]{64}$/.test(hash)).assertTrue();
      expect(salt.length).assertEqual(16);
      // 存储里不再出现明文 PIN
      const store = mock.prefs.get(STORE) as Map<string, Object>;
      expect(store.get('lock_pin') as string).assertEqual('');
    });

    it('正确 PIN 校验通过，错误 PIN 失败', 0, async () => {
      const ctx = fakeContext();
      await EventStore.saveLockPin(ctx, '4321');
      expect(EventStore.verifyLockPin(ctx, '4321').ok).assertTrue();
      expect(EventStore.verifyLockPin(ctx, '1234').ok).assertFalse();
    });

    it('修改 PIN 后旧 PIN 立即失效', 0, async () => {
      const ctx = fakeContext();
      await EventStore.saveLockPin(ctx, '1111');
      await EventStore.saveLockPin(ctx, '2222');
      expect(EventStore.verifyLockPin(ctx, '1111').ok).assertFalse();
      expect(EventStore.verifyLockPin(ctx, '2222').ok).assertTrue();
    });

    it('关闭后清空全部锁数据', 0, async () => {
      const ctx = fakeContext();
      await EventStore.saveLockPin(ctx, '1234');
      await EventStore.disableLock(ctx);
      expect(EventStore.isLockEnabled(ctx)).assertFalse();
      expect(EventStore.getLockHash(ctx)).assertEqual('');
      expect(EventStore.getLockSalt(ctx)).assertEqual('');
      expect(EventStore.getLegacyPin(ctx)).assertEqual('');
    });

    it('旧版明文 PIN 校验通过后自动升级为摘要', 0, async () => {
      const ctx = fakeContext();
      seedKey('lock_enabled', true);
      seedKey('lock_pin', '8888');
      const result = EventStore.verifyLockPin(ctx, '8888');
      expect(result.ok).assertTrue();
      expect(result.legacy).assertTrue();
      await tick();
      expect(EventStore.getLockHash(ctx).length).assertEqual(64);
      expect(EventStore.getLegacyPin(ctx)).assertEqual('');
    });

    it('旧版明文 PIN 错误时不迁移', 0, async () => {
      const ctx = fakeContext();
      seedKey('lock_enabled', true);
      seedKey('lock_pin', '8888');
      const result = EventStore.verifyLockPin(ctx, '0000');
      expect(result.ok).assertFalse();
      expect(result.legacy).assertTrue();
      await tick();
      expect(EventStore.getLockHash(ctx)).assertEqual('');
      expect(EventStore.getLegacyPin(ctx)).assertEqual('8888');
    });

    it('迁移写入失败时仍返回校验通过且不抛异常', 0, async () => {
      const ctx = fakeContext();
      seedKey('lock_enabled', true);
      seedKey('lock_pin', '8888');
      mock.fail.put = true;
      const result = EventStore.verifyLockPin(ctx, '8888');
      expect(result.ok).assertTrue();
      await tick();
      mock.fail.put = false;
      expect(true).assertTrue();
    });

    it('上下文不可用时返回安全默认值', 0, () => {
      const ctx = brokenContext();
      expect(EventStore.isLockEnabled(ctx)).assertFalse();
      expect(EventStore.getLockHash(ctx)).assertEqual('');
      expect(EventStore.getLockSalt(ctx)).assertEqual('');
      expect(EventStore.getLegacyPin(ctx)).assertEqual('');
      expect(EventStore.verifyLockPin(ctx, '1234').ok).assertFalse();
    });

    it('写入失败不抛异常', 0, async () => {
      mock.fail.put = true;
      await EventStore.saveLockPin(fakeContext(), '1234');
      await EventStore.disableLock(fakeContext());
      expect(true).assertTrue();
    });
  });
}
