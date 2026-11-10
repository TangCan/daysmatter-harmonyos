/** @kit.ArkData 桩：Preferences 内存实现 */
const { state, prefsMap } = require('../state');

function makePref(name) {
  const map = prefsMap(name);
  return {
    async get(key, def) {
      return map.has(key) ? map.get(key) : def;
    },
    getSync(key, def) {
      return map.has(key) ? map.get(key) : def;
    },
    async put(key, value) {
      if (state.fail.put) {
        throw new Error('mock put failure');
      }
      map.set(key, value);
      return true;
    },
    async flush() {
      if (state.fail.flush) {
        throw new Error('mock flush failure');
      }
      state.prefFlushCount++;
      return true;
    },
    deleteSync(key) {
      map.delete(key);
    }
  };
}

const preferences = {
  getPreferences(context, name) {
    // 约定：fail.getPreferencesThrowSync 模拟环境不支持时同步抛错
    if (state.fail.getPreferencesThrowSync) {
      throw new Error('mock getPreferences sync failure');
    }
    if (state.fail.getPreferences) {
      return Promise.reject(new Error('mock getPreferences failure'));
    }
    return Promise.resolve(makePref(name));
  },
  getPreferencesSync(context, options) {
    if (state.fail.getPreferencesSync) {
      throw new Error('mock getPreferencesSync failure');
    }
    return makePref(options.name);
  }
};

module.exports = { preferences };
