/**
 * 单元测试辅助：访问覆盖率运行器注入的 mock 状态
 * 说明：本文件只在 tools/coverage 的 Node 运行器下有意义；
 * 在 DevEco 真机/模拟器上运行 ohosTest 时不使用这些用例。
 */
import { state, resetState } from '../../../../tools/coverage/state';
import { common } from '@kit.AbilityKit';

export interface ReminderRequestMock {
  title: string;
  content: string;
  dateTime: DateMock;
  repeatMonths?: number[];
  repeatDays?: number[];
  reminderType?: number;
}

export interface DateMock {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
}

export interface FormUpdateMock {
  formId: string;
  data: Record<string, string>;
}

export interface MockState {
  prefs: Map<string, Map<string, Object>>;
  prefFlushCount: number;
  fail: MockFail;
  forms: MockForms;
  reminders: MockReminders;
  notify: MockNotify;
  fs: MockFs;
  picker: MockPicker;
  logs: Object[];
}

export interface MockFail {
  getPreferences: boolean;
  getPreferencesSync: boolean;
  getPreferencesThrowSync: boolean;
  put: boolean;
  flush: boolean;
}

export interface MockForms {
  ids: string[];
  dims: Record<string, number>;
  updates: FormUpdateMock[];
  throwFor: string[];
}

export interface MockReminders {
  published: ReminderRequestMock[];
  cancelled: number[];
  nextId: number;
}

export interface MockNotify {
  enabled: boolean;
  throwOnRequest: boolean;
  requestCount: number;
}

export interface MockFs {
  files: Map<string, Object>;
}

export interface MockPicker {
  saveUris: string[];
  selectUris: string[];
}

export const mock = state as Object as MockState;

export function resetMock(): void {
  resetState();
}

/**
 * 等待微任务 / 定时器队列清空（用于验证"发射后不管"的异步写入）
 */
export function tick(): Promise<void> {
  return new Promise<void>((resolve: () => void) => {
    setTimeout(() => {
      resolve();
    }, 0);
  });
}

/**
 * 可用的应用上下文（Mock 版）
 */
export function fakeContext(): common.Context {
  const ctx = {
    getApplicationContext: (): Object => ctx
  } as Object as common.Context;
  return ctx;
}

/**
 * 取上下文即抛错的"坏上下文"，用于验证各处 try/catch 降级
 */
export function brokenContext(): common.Context {
  const ctx = {
    getApplicationContext: (): Object => {
      throw new Error('mock context failure');
    }
  } as Object as common.Context;
  return ctx;
}

/**
 * 通知授权一定会被拒绝的上下文
 */
export function deniedContext(): common.UIAbilityContext {
  const ctx = {
    getApplicationContext: (): Object => ctx,
    __failNotify: true
  } as Object as common.UIAbilityContext;
  return ctx;
}

/**
 * UIAbilityContext（Mock 版）
 */
export function abilityContext(): common.UIAbilityContext {
  return fakeContext() as Object as common.UIAbilityContext;
}
