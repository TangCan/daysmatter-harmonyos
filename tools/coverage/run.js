#!/usr/bin/env node
/**
 * 单元测试 + 覆盖率一键执行
 * 用法： node tools/coverage/run.js [--threshold=95]
 */
const { spawnSync } = require('child_process');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const args = process.argv.slice(2);
let threshold = 95;
for (const a of args) {
  const m = /^--threshold=(\d+(?:\.\d+)?)$/.exec(a);
  if (m) {
    threshold = Number(m[1]);
  }
}

const build = spawnSync(process.execPath, [path.join(__dirname, 'build.js')], { cwd: ROOT, stdio: 'inherit' });
if (build.status !== 0) {
  process.exit(build.status || 1);
}

const cliArgs = [
  '--test',
  '--experimental-test-coverage',
  '--enable-source-maps',
  `--test-coverage-lines=${threshold}`,
  `--test-coverage-branches=${threshold}`,
  `--test-coverage-functions=${threshold}`,
  '--test-coverage-exclude=**/WorkBuddy.app/**',
  '--test-coverage-exclude=**/node_modules/**',
  '--test-coverage-exclude=**/tools/**',
  '--test-coverage-exclude=**/tests-out/**',
  path.join(__dirname, 'runner.test.js')
];

const run = spawnSync(process.execPath, cliArgs, { cwd: ROOT, stdio: 'inherit' });
process.exit(run.status === null ? 1 : run.status);
