/**
 * 测试运行时共享状态（供各 @kit 桩模块读写）
 * 只在 Node 覆盖率测试中使用，不参与应用构建
 */
function freshState() {
  return {
    prefs: new Map(),          // name -> Map(key, value)
    prefFlushCount: 0,
    fail: {
      getPreferences: false,
      getPreferencesSync: false,
      getPreferencesThrowSync: false,
      put: false,
      flush: false
    },
    forms: {
      ids: [],
      dims: {},
      updates: [],
      throwFor: []
    },
    reminders: {
      published: [],
      cancelled: [],
      failPublish: false,
      failCancel: false,
      nextId: 100
    },
    notify: {
      enabled: true,
      throwOnRequest: false,
      requestCount: 0
    },
    fs: {
      files: new Map(),        // path -> Buffer
      nextFd: 10,
      fds: new Map()           // fd -> path
    },
    picker: {
      saveUris: [],
      selectUris: [],
      saveOptions: null,
      selectOptions: null,
      throwOnSave: false,
      throwOnSelect: false
    },
    logs: []
  };
}

const state = freshState();

function resetState() {
  Object.assign(state, freshState());
}

function prefsMap(name) {
  if (!state.prefs.has(name)) {
    state.prefs.set(name, new Map());
  }
  return state.prefs.get(name);
}

module.exports = { state, resetState, prefsMap };
