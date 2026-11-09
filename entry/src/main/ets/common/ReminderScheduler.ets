/**
 * 本地提醒通知调度
 * - 使用 reminderAgentManager 日历提醒（系统级定时，应用被杀也能触发）
 * - 提醒时间固定为当天 09:00；每年重复的事件通过 repeatMonths/repeatDays 每年循环
 * - 全部为本地通知，不涉及任何网络与个人信息
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { CountdownEvent, effectiveDate } from '../model/CountdownEvent';

const REMIND_HOUR = 9;
const REMIND_MINUTE = 0;

export class ReminderScheduler {
  /**
   * 请求通知授权（系统弹窗，仅首次）。返回当前是否已授权。
   */
  static async ensureNotificationEnabled(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      if (enabled) {
        return true;
      }
      await notificationManager.requestEnableNotification(context);
      return await notificationManager.isNotificationEnabled();
    } catch (err) {
      // 用户拒绝授权或环境不支持：提醒功能静默降级
      return false;
    }
  }

  /**
   * 为事件安排提醒，返回系统分配的 reminderId（0 = 未安排）
   */
  static async scheduleFor(context: common.UIAbilityContext, item: CountdownEvent): Promise<number> {
    if (item.remindMode === 0) {
      return 0;
    }
    const granted = await ReminderScheduler.ensureNotificationEnabled(context);
    if (!granted) {
      return 0;
    }

    const parts = effectiveDate(item).split('-');
    if (parts.length !== 3) {
      return 0;
    }
    let ty = Number(parts[0]);
    let tm = Number(parts[1]);
    let td = Number(parts[2]);
    if (Number.isNaN(ty) || Number.isNaN(tm) || Number.isNaN(td)) {
      return 0;
    }
    // 提前 1 天模式
    if (item.remindMode === 2) {
      const base = new Date(ty, tm - 1, td);
      base.setDate(base.getDate() - 1);
      ty = base.getFullYear();
      tm = base.getMonth() + 1;
      td = base.getDate();
    }

    const now = new Date();
    const trigger = new Date(ty, tm - 1, td, REMIND_HOUR, REMIND_MINUTE);
    if (trigger.getTime() <= now.getTime()) {
      // 触发时间已过：一次性事件不再安排（每年重复事件由 repeat 规则接管）
      if (!item.repeatYearly) {
        return 0;
      }
    }

    const request: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: ty,
        month: tm,
        day: td,
        hour: REMIND_HOUR,
        minute: REMIND_MINUTE
      },
      title: `${item.name}`,
      content: item.remindMode === 2 ? `明天就是「${item.name}」了，记得那天` : `「${item.name}」，记得那天`
    };
    if (item.repeatYearly) {
      // 每年重复：按触发日的 月-日 每年循环（提前 1 天模式同样适用）
      request.repeatMonths = [tm];
      request.repeatDays = [td];
    }
    try {
      const id = await reminderAgentManager.publishReminder(request);
      return id;
    } catch (err) {
      return 0;
    }
  }

  /**
   * 取消已安排的提醒（id <= 0 表示没有安排过，直接跳过）
   */
  static async cancel(reminderId: number): Promise<void> {
    if (reminderId <= 0) {
      return;
    }
    try {
      await reminderAgentManager.cancelReminder(reminderId);
    } catch (err) {
      // 提醒可能已被系统清理，忽略
    }
  }
}
