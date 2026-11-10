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

    it('默认关闭且无 PIN', 0, () => {
      const ctx = fakeContext();
      expect(EventStore.isLockEnabled(ctx)).assertFalse();
      expect(EventStore.getLockPin(ctx)).assertEqual('');
    });

    it('开启后可读到 PIN', 0, async () => {
      const ctx = fakeContext();
      await EventStore.saveLock(ctx, true, '1234');
      expect(EventStore.isLockEnabled(ctx)).assertTrue();
      expect(EventStore.getLockPin(ctx)).assertEqual('1234');
    });

    it('关闭后清空 PIN', 0, async () => {
      const ctx = fakeContext();
      await EventStore.saveLock(ctx, true, '1234');
      await EventStore.saveLock(ctx, false, '');
      expect(EventStore.isLockEnabled(ctx)).assertFalse();
      expect(EventStore.getLockPin(ctx)).assertEqual('');
    });

    it('上下文不可用时返回默认值', 0, () => {
      const ctx = brokenContext();
      expect(EventStore.isLockEnabled(ctx)).assertFalse();
      expect(EventStore.getLockPin(ctx)).assertEqual('');
    });

    it('写入失败不抛异常', 0, async () => {
      mock.fail.put = true;
      await EventStore.saveLock(fakeContext(), true, '1234');
      expect(true).assertTrue();
    });
  });
}
