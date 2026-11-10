/** @kit.PerformanceAnalysisKit 桩 */
const { state } = require('../state');

const hilog = {
  info(domain, tag, format, ...args) {
    state.logs.push({ level: 'info', tag, format, args });
  },
  error(domain, tag, format, ...args) {
    state.logs.push({ level: 'error', tag, format, args });
  },
  warn(domain, tag, format, ...args) {
    state.logs.push({ level: 'warn', tag, format, args });
  }
};

module.exports = { hilog };
