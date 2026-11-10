/** @kit.FormKit 桩 */
const { state } = require('../state');

const formProvider = {
  async updateForm(formId, data) {
    // 约定：事件名为 __fail__ 时模拟卡片已被移除导致的推送失败
    if (state.forms.throwFor.indexOf(formId) >= 0 || (data && data.eventName === '__fail__')) {
      throw new Error('mock updateForm failure');
    }
    state.forms.updates.push({ formId, data });
  }
};

const formBindingData = {
  createFormBindingData(obj) {
    return obj;
  }
};

module.exports = { formProvider, formBindingData };
