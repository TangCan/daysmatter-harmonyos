/**
 * 把 ArkTS 源码(.ets)转成 CommonJS，供 Node 覆盖率测试执行
 * - 只处理纯逻辑模块（model/ 与 common/），页面与卡片（UI DSL）不参与
 * - @kit.* 系统能力替换为 tools/coverage/stubs 下的桩
 * - 保留 inline source map，使覆盖率报告直接映射回 .ets 源码
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const SRC_ROOT = path.join(ROOT, 'entry/src/main/ets');
const TEST_ROOT = path.join(ROOT, 'entry/src/test');
const OUT_ROOT = path.join(ROOT, '.coverage');
const OUT_APP = path.join(OUT_ROOT, 'out');
const OUT_TEST = path.join(OUT_ROOT, 'tests-out');
const STUBS = path.join(__dirname, 'stubs');

const KIT_STUBS = {
  '@kit.ArkData': path.join(STUBS, 'kit-arkdata.js'),
  '@kit.AbilityKit': path.join(STUBS, 'kit-ability.js'),
  '@kit.FormKit': path.join(STUBS, 'kit-form.js'),
  '@kit.PerformanceAnalysisKit': path.join(STUBS, 'kit-hilog.js'),
  '@kit.BackgroundTasksKit': path.join(STUBS, 'kit-reminder.js'),
  '@kit.NotificationKit': path.join(STUBS, 'kit-notification.js'),
  '@kit.CoreFileKit': path.join(STUBS, 'kit-file.js'),
  '@kit.ArkTS': path.join(STUBS, 'kit-arkts.js')
};

function loadTypeScript() {
  const candidates = [
    '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript',
    '/Applications/DevEco-Studio.app/Contents/tools/ohpm/node_modules/typescript'
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) {
      return require(c);
    }
  }
  return require('typescript');
}

const ts = loadTypeScript();

function walk(dir, exts, acc) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, exts, acc);
    } else if (exts.some((e) => full.endsWith(e))) {
      acc.push(full);
    }
  }
  return acc;
}

function relativeSpecifier(fromFile, toFile) {
  let rel = path.relative(path.dirname(fromFile), toFile).split(path.sep).join('/');
  rel = rel.replace(/\.js$/, '');
  if (!rel.startsWith('.')) {
    rel = './' + rel;
  }
  return rel;
}

function rewriteSpecifiers(text, sourceFile, outFile, isTest) {
  return text.replace(/(['"])(@kit\.[A-Za-z]+|@ohos\/hypium|\.\.\/main\/ets\/[^'"]+)(['"])/g,
    (match, q1, spec, q2) => {
      if (spec === '@ohos/hypium') {
        return `${q1}${relativeSpecifier(outFile, path.join(__dirname, 'hypium.js'))}${q2}`;
      }
      if (KIT_STUBS[spec]) {
        return `${q1}${relativeSpecifier(outFile, KIT_STUBS[spec])}${q2}`;
      }
      if (spec.startsWith('../main/ets/')) {
        const rel = spec.substring('../main/ets/'.length);
        const target = path.join(OUT_APP, rel);
        return `${q1}${relativeSpecifier(outFile, target)}${q2}`;
      }
      return match;
    });
}

function transpile(etsFile, outFile, isTest) {
  const original = fs.readFileSync(etsFile, 'utf8');
  const rewritten = rewriteSpecifiers(original, etsFile, outFile, isTest);
  const res = ts.transpileModule(rewritten, {
    fileName: etsFile,
    reportDiagnostics: false,
    compilerOptions: {
      target: ts.ScriptTarget.ES2021,
      module: ts.ModuleKind.CommonJS,
      esModuleInterop: true,
      sourceMap: true,
      inlineSources: true
    }
  });
  let code = res.outputText.replace(/\n?\/\/# sourceMappingURL=.*$/m, '');
  const map = JSON.parse(res.sourceMapText);
  map.sources = [etsFile];
  map.sourcesContent = [original];
  map.file = outFile;
  delete map.sourceRoot;
  code += '\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,'
    + Buffer.from(JSON.stringify(map)).toString('base64') + '\n';
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, code);
  return code.length;
}

function clean() {
  fs.rmSync(OUT_ROOT, { recursive: true, force: true });
}

function main() {
  clean();

  // 1) 应用逻辑模块
  const dirs = ['model', 'common'];
  let count = 0;
  for (const d of dirs) {
    const base = path.join(SRC_ROOT, d);
    for (const file of walk(base, ['.ets'], [])) {
      const rel = path.relative(SRC_ROOT, file).replace(/\.ets$/, '.js');
      transpile(file, path.join(OUT_APP, rel), false);
      count++;
    }
  }

  // 2) 测试用例（输出到独立目录，便于覆盖率统计时只保留应用代码）
  const testFiles = walk(TEST_ROOT, ['.test.ets', '.ets'], []);
  for (const file of testFiles) {
    const rel = path.relative(TEST_ROOT, file).replace(/\.ets$/, '.js');
    transpile(file, path.join(OUT_TEST, 'test', rel), true);
    count++;
  }

  // 3) node:test 入口
  const runner = `const test = require('node:test');
const assert = require('node:assert');
const hypium = require(${JSON.stringify(path.join(__dirname, 'hypium.js'))});

test('hypium unit suites', async () => {
  const mod = require(${JSON.stringify(path.join(OUT_TEST, 'test', 'List.test.js'))});
  const suite = typeof mod === 'function' ? mod : mod.default;
  suite();
  const res = await hypium.runAll();
  if (res.failures.length > 0) {
    for (const f of res.failures) {
      console.error('\\n[FAIL] ' + f.suite + ' > ' + f.name);
      console.error('       ' + (f.error && f.error.message ? f.error.message : String(f.error)));
    }
  }
  console.log('\\n用例统计: 通过 ' + res.passed + ' / 失败 ' + res.failed);
  assert.strictEqual(res.failed, 0, res.failed + ' 个用例失败');
});
`;
  fs.writeFileSync(path.join(__dirname, 'runner.test.js'), runner);
  console.log(`已转译 ${count} 个文件（应用代码 -> .coverage/out，测试 -> .coverage/tests-out）`);
}

main();
