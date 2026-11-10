/**
 * @ohos/hypium 兼容层（用于 Node 覆盖率测试）
 * 实现 describe / it / 生命周期钩子 / expect 断言子集，
 * 使 entry/src/test 下的用例可以直接在 Node 中执行。
 */

class AssertionError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AssertionError';
  }
}

const root = { name: '(root)', tests: [], suites: [], beforeAll: [], afterAll: [], beforeEach: [], afterEach: [], parent: null };
let current = root;

const result = { passed: 0, failed: 0, failures: [], skipped: 0 };

function describe(name, fn) {
  const suite = { name, tests: [], suites: [], beforeAll: [], afterAll: [], beforeEach: [], afterEach: [], parent: current };
  current.suites.push(suite);
  const prev = current;
  current = suite;
  try {
    fn();
  } catch (e) {
    result.failures.push({ suite: suitePath(suite), name: '<describe 注册阶段>', error: e });
    result.failed++;
  } finally {
    current = prev;
  }
}

function suitePath(suite) {
  const parts = [];
  let s = suite;
  while (s && s !== root) {
    parts.unshift(s.name);
    s = s.parent;
  }
  return parts.join(' > ');
}

function it(name, filter, fn) {
  const body = typeof filter === 'function' ? filter : fn;
  const timeout = typeof filter === 'number' ? filter : 0;
  current.tests.push({ name, body, timeout });
}

function beforeAll(fn) { current.beforeAll.push(fn); }
function afterAll(fn) { current.afterAll.push(fn); }
function beforeEach(fn) { current.beforeEach.push(fn); }
function afterEach(fn) { current.afterEach.push(fn); }

function ancestors(suite) {
  const chain = [];
  let s = suite;
  while (s && s !== root) {
    chain.unshift(s);
    s = s.parent;
  }
  return chain;
}

async function runSuite(suite) {
  const chain = ancestors(suite);
  for (const s of chain) {
    for (const hook of s.beforeAll) {
      await hook();
    }
  }
  for (const t of suite.tests) {
    try {
      for (const s of chain) {
        for (const hook of s.beforeEach) {
          await hook();
        }
      }
      await t.body();
      result.passed++;
    } catch (e) {
      result.failed++;
      result.failures.push({ suite: suitePath(suite), name: t.name, error: e });
    } finally {
      for (const s of chain.slice().reverse()) {
        for (const hook of s.afterEach) {
          try {
            await hook();
          } catch (e) {
            // 清理钩子失败不改变用例结果
          }
        }
      }
    }
  }
  for (let i = suite.suites.length - 1; i >= 0; i--) {
    await runSuite(suite.suites[i]);
  }
  for (const s of chain.slice().reverse()) {
    for (const hook of s.afterAll) {
      try {
        await hook();
      } catch (e) {
        // 忽略
      }
    }
  }
}

async function runAll() {
  for (const suite of root.suites) {
    await runSuite(suite);
  }
  return result;
}

// ---------------- expect ----------------

function format(v) {
  if (typeof v === 'string') {
    return JSON.stringify(v);
  }
  try {
    return JSON.stringify(v);
  } catch (e) {
    return String(v);
  }
}

function deepEqual(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function buildMatchers(actual, negated) {
  const check = (ok, message) => {
    if (negated ? ok : !ok) {
      throw new AssertionError((negated ? 'NOT ' : '') + message);
    }
  };
  return {
    assertEqual(expected) {
      check(actual === expected, `expect ${format(actual)} to equal ${format(expected)}`);
    },
    assertNotEqual(expected) {
      check(actual !== expected, `expect ${format(actual)} not to equal ${format(expected)}`);
    },
    assertTrue() {
      check(actual === true, `expect ${format(actual)} to be true`);
    },
    assertFalse() {
      check(actual === false, `expect ${format(actual)} to be false`);
    },
    assertNull() {
      check(actual === null, `expect ${format(actual)} to be null`);
    },
    assertUndefined() {
      check(actual === undefined, `expect ${format(actual)} to be undefined`);
    },
    assertContain(expected) {
      let ok = false;
      if (typeof actual === 'string') {
        ok = actual.indexOf(expected) >= 0;
      } else if (Array.isArray(actual)) {
        ok = actual.indexOf(expected) >= 0;
      }
      check(ok, `expect ${format(actual)} to contain ${format(expected)}`);
    },
    assertLarger(expected) {
      check(actual > expected, `expect ${format(actual)} > ${format(expected)}`);
    },
    assertLess(expected) {
      check(actual < expected, `expect ${format(actual)} < ${format(expected)}`);
    },
    assertClose(expected, delta) {
      check(Math.abs(actual - expected) <= delta, `expect ${format(actual)} close to ${format(expected)}`);
    },
    assertInstanceOf(type) {
      check(actual instanceof type, `expect ${format(actual)} to be instance of ${type && type.name}`);
    },
    assertDeepEquals(expected) {
      check(deepEqual(actual, expected), `expect ${format(actual)} to deep equal ${format(expected)}`);
    },
    assertNaN() {
      check(typeof actual === 'number' && Number.isNaN(actual), `expect ${format(actual)} to be NaN`);
    },
    assertThrowError(message) {
      let threw = false;
      let thrown = null;
      try {
        actual();
      } catch (e) {
        threw = true;
        thrown = e;
      }
      if (message && thrown && thrown.message) {
        check(threw && thrown.message.indexOf(message) >= 0, `expect thrown message to contain ${format(message)}`);
      } else {
        check(threw, 'expect function to throw');
      }
    },
    not() {
      return buildMatchers(actual, !negated);
    }
  };
}

function expect(actual) {
  return buildMatchers(actual, false);
}

module.exports = {
  describe,
  it,
  beforeAll,
  afterAll,
  beforeEach,
  afterEach,
  expect,
  runAll,
  result,
  AssertionError
};
