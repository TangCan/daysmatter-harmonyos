import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { ReminderScheduler } from '../main/ets/common/ReminderScheduler';
import { CountdownEvent, formatDate, effectiveDate } from '../main/ets/model/CountdownEvent';
import { mock, resetMock, fakeContext, abilityContext, deniedContext } from './helpers/Harness';

function today0(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function isoShift(days: number): string {
  const d = new Date(today0().getTime() + days * 86400000);
  return formatDate(new Date(d.getFullYear(), d.getMonth(), d.getDate()));
}

function ev(name: string, dateStr: string, mode: number, repeat: boolean): CountdownEvent {
  const e = new CountdownEvent();
  e.id = 'id-' + name;
  e.name = name;
  e.targetDate = dateStr;
  e.remindMode = mode;
  e.repeatYearly = repeat;
  return e;
}

export default function reminderSchedulerTest() {
  describe('ReminderScheduler.通知授权', () => {
    beforeEach(() => {
      resetMock();
    });

    it('已授权时直接返回 true 不再请求', 0, async () => {
      mock.notify.enabled = true;
      const ok = await ReminderScheduler.ensureNotificationEnabled(abilityContext());
      expect(ok).assertTrue();
      expect(mock.notify.requestCount).assertEqual(0);
    });

    it('未授权时请求并重新检查', 0, async () => {
      mock.notify.enabled = false;
      const ok = await ReminderScheduler.ensureNotificationEnabled(abilityContext());
      expect(ok).assertTrue();
      expect(mock.notify.requestCount).assertEqual(1);
    });

    it('用户拒绝授权时返回 false', 0, async () => {
      mock.notify.enabled = false;
      const ok = await ReminderScheduler.ensureNotificationEnabled(deniedContext());
      expect(ok).assertFalse();
    });
  });

  describe('ReminderScheduler.scheduleFor', () => {
    beforeEach(() => {
      resetMock();
      mock.notify.enabled = true;
    });

    it('不提醒模式不发布任何提醒', 0, async () => {
      const id = await ReminderScheduler.scheduleFor(abilityContext(), ev('生日', isoShift(3), 0, false));
      expect(id).assertEqual(0);
      expect(mock.reminders.published.length).assertEqual(0);
    });

    it('当天提醒：标题为事件名，内容含提示语', 0, async () => {
      const target = isoShift(3);
      const id = await ReminderScheduler.scheduleFor(abilityContext(), ev('考试', target, 1, false));
      expect(id).assertLarger(0);
      const req = mock.reminders.published[0];
      expect(req.title).assertEqual('考试');
      expect(req.content).assertContain('记得那天');
      expect(req.dateTime.day).assertEqual(Number(target.substring(8)));
      expect(req.dateTime.hour).assertEqual(9);
      expect(req.repeatMonths === undefined).assertTrue();
    });

    it('提前 1 天提醒：触发日减一天并改文案', 0, async () => {
      const target = isoShift(3);
      await ReminderScheduler.scheduleFor(abilityContext(), ev('旅行', target, 2, false));
      const req = mock.reminders.published[0];
      expect(req.content).assertContain('明天就是');
      const expected = new Date(target + 'T00:00:00');
      expected.setDate(expected.getDate() - 1);
      expect(req.dateTime.day).assertEqual(expected.getDate());
    });

    it('每年重复的事件按 月-日 循环', 0, async () => {
      const target = isoShift(5);
      await ReminderScheduler.scheduleFor(abilityContext(), ev('生日', target, 1, true));
      const req = mock.reminders.published[0];
      const parts = effectiveDate(ev('生日', target, 1, true)).split('-');
      expect((req.repeatMonths as number[])[0]).assertEqual(Number(parts[1]));
      expect((req.repeatDays as number[])[0]).assertEqual(Number(parts[2]));
    });

    it('未授权且用户拒绝时不安排提醒', 0, async () => {
      mock.notify.enabled = false;
      const id = await ReminderScheduler.scheduleFor(deniedContext(), ev('生日', isoShift(3), 1, false));
      expect(id).assertEqual(0);
      expect(mock.reminders.published.length).assertEqual(0);
    });

    it('一次性事件日期已过不再安排', 0, async () => {
      const id = await ReminderScheduler.scheduleFor(abilityContext(), ev('旧事', isoShift(-3), 1, false));
      expect(id).assertEqual(0);
      expect(mock.reminders.published.length).assertEqual(0);
    });

    it('每年重复事件日期已过仍按明年安排', 0, async () => {
      const id = await ReminderScheduler.scheduleFor(abilityContext(), ev('纪念日', isoShift(-3), 1, true));
      expect(id).assertLarger(0);
      expect(mock.reminders.published.length).assertEqual(1);
    });

    it('日期非法时不安排提醒', 0, async () => {
      const noDash = await ReminderScheduler.scheduleFor(abilityContext(), ev('坏日期', 'abc', 1, false));
      expect(noDash).assertEqual(0);
      const badNumber = await ReminderScheduler.scheduleFor(abilityContext(), ev('坏日期2', '2020-xx-01', 1, false));
      expect(badNumber).assertEqual(0);
      expect(mock.reminders.published.length).assertEqual(0);
    });

    it('系统拒绝发布提醒时返回 0', 0, async () => {
      const id = await ReminderScheduler.scheduleFor(abilityContext(), ev('__fail__', isoShift(3), 1, false));
      expect(id).assertEqual(0);
    });
  });

  describe('ReminderScheduler.cancel', () => {
    beforeEach(() => {
      resetMock();
    });

    it('id<=0 视为未安排直接跳过', 0, async () => {
      await ReminderScheduler.cancel(0);
      await ReminderScheduler.cancel(-5);
      expect(mock.reminders.cancelled.length).assertEqual(0);
    });

    it('正常取消已安排的提醒', 0, async () => {
      await ReminderScheduler.cancel(42);
      expect(mock.reminders.cancelled.length).assertEqual(1);
      expect(mock.reminders.cancelled[0]).assertEqual(42);
    });

    it('提醒已被系统清理时静默失败', 0, async () => {
      await ReminderScheduler.cancel(777777);
      expect(true).assertTrue();
    });
  });
}
