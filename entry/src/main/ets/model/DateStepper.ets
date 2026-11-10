/**
 * 日期步进器 / 日期计算器的纯逻辑（从 Index 页面抽离，便于单元测试）
 */
import { formatDate, workingDaysBetween } from './CountdownEvent';

export interface DateSelection {
  year: number;
  month: number; // 1~12
  day: number;   // 1~31
}

export const MIN_YEAR = 1900;
export const MAX_YEAR = 2080;

/**
 * 某年某月的天数（m 为 1~12）
 */
export function daysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

function clampDay(y: number, m: number, d: number): number {
  return Math.min(d, daysInMonth(y, m));
}

/**
 * 步进一次日期选择。
 * - label: '年' / '月' / '日'
 * - repeatYearly: 每年重复的事件允许停在过去的日期（生日）
 * 返回 undefined 表示本次操作无效（超范围或早于今天）
 */
export function stepSelection(
  cur: DateSelection,
  label: string,
  delta: number,
  repeatYearly: boolean,
  today: Date
): DateSelection | undefined {
  let y = cur.year;
  let m = cur.month;
  let d = cur.day;

  if (label === '年') {
    y += delta;
  } else if (label === '月') {
    m += delta;
    if (m > 12) {
      m = 1;
      y += 1;
    } else if (m < 1) {
      m = 12;
      y -= 1;
    }
  } else {
    d += delta;
    if (d > daysInMonth(y, m)) {
      d = 1;
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    } else if (d < 1) {
      m -= 1;
      if (m < 1) {
        m = 12;
        y -= 1;
      }
      d = daysInMonth(y, m);
    }
  }

  if (y < MIN_YEAR || y > MAX_YEAR) {
    return undefined;
  }
  d = clampDay(y, m, d);
  if (!repeatYearly) {
    const today0 = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    if (new Date(y, m - 1, d).getTime() < today0.getTime()) {
      return undefined;
    }
  }
  const next: DateSelection = { year: y, month: m, day: d };
  return next;
}

/**
 * 日期计算器结果文案：两日期间隔 + 工作日，可选叠加天数推算
 */
export function calcDateRange(dateA: string, dateB: string, daysStr: string): string {
  const a = new Date(dateA + 'T00:00:00');
  const b = new Date(dateB + 'T00:00:00');
  if (Number.isNaN(a.getTime()) || Number.isNaN(b.getTime())) {
    return '请输入有效日期（格式 yyyy-MM-dd）';
  }
  const diff = Math.round((b.getTime() - a.getTime()) / 86400000);
  const wd = workingDaysBetween(dateA, dateB);
  let line = diff >= 0 ? `间隔 ${diff} 天，其中 ${wd} 个工作日` : `间隔 ${-diff} 天（结束早于开始），其中 ${wd} 个工作日`;
  const n = Number(daysStr);
  if (daysStr.trim().length > 0 && !Number.isNaN(n)) {
    const shifted = new Date(a.getTime() + n * 86400000);
    line += `；${dateA} ${n >= 0 ? '+' : ''}${n} 天 = ${formatDate(shifted)}`;
  }
  return line;
}
