/** @kit.NotificationKit 桩 */
const { state } = require('../state');

const notificationManager = {
  async isNotificationEnabled() {
    return state.notify.enabled;
  },
  async requestEnableNotification(context) {
    state.notify.requestCount++;
    // 约定：context.__failNotify = true 时模拟用户拒绝授权
    if (state.notify.throwOnRequest || (context && context.__failNotify === true)) {
      throw new Error('mock requestEnableNotification failure');
    }
    state.notify.enabled = true;
  }
};

module.exports = { notificationManager };
