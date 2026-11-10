/** @kit.BackgroundTasksKit 桩：reminderAgentManager */
const { state } = require('../state');

const ReminderType = {
  REMINDER_TYPE_CALENDAR: 0,
  REMINDER_TYPE_TIMER: 1,
  REMINDER_TYPE_ALARM: 2
};

const reminderAgentManager = {
  ReminderType,
  async publishReminder(request) {
    // 约定：标题包含 __fail__ 时模拟系统拒绝发布
    if (state.reminders.failPublish || (request.title && request.title.indexOf('__fail__') >= 0)) {
      throw new Error('mock publishReminder failure');
    }
    state.reminders.published.push(request);
    const id = state.reminders.nextId++;
    return id;
  },
  async cancelReminder(reminderId) {
    // 约定：id 为 777777 时模拟提醒已被系统清理
    if (state.reminders.failCancel || reminderId === 777777) {
      throw new Error('mock cancelReminder failure');
    }
    state.reminders.cancelled.push(reminderId);
  }
};

module.exports = { reminderAgentManager, ReminderType };
