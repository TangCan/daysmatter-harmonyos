/**
 * 倒数日数据模型
 */
export interface CategoryOption {
  key: string;
  label: string;
  emoji: string;
}

export const CATEGORY_OPTIONS: CategoryOption[] = [
  { key: 'birthday', label: '生日', emoji: '🎂' },
  { key: 'anniversary', label: '纪念日', emoji: '💐' },
  { key: 'festival', label: '节日', emoji: '🎉' },
  { key: 'work', label: '工作', emoji: '💼' },
  { key: 'other', label: '其他', emoji: '📌' }
];

export function categoryOption(key: string): CategoryOption {
  const found = CATEGORY_OPTIONS.find((c: CategoryOption) => c.key === key);
  return found !== undefined ? found : CATEGORY_OPTIONS[4];
}

/**
 * 事件准备清单条目
 */
export interface ChecklistItem {
  text: string;
  done: boolean;
}

export class CountdownEvent {
  id: string = '';
  name: string = '';
  targetDate: string = ''; // 格式 yyyy-MM-dd；开启每年重复时允许是过去的原始日期
  category: string = 'other';
  note: string = '';
  repeatYearly: boolean = false;
  pinned: boolean = false;
  createdAt: number = 0;
  remindMode: number = 0;  // 0=不提醒 1=当天提醒 2=提前1天提醒
  reminderId: number = 0;  // 系统提醒代理分配的 id，0=未安排
  items: ChecklistItem[] = [];  // 事件准备清单（待办事项）
  background: string = '';      // 事件照片背景（应用沙箱内的绝对路径，空=无）

  static fromJson(obj: CountdownEvent): CountdownEvent {
    const e = new CountdownEvent();
    e.id = obj.id !== undefined ? obj.id : '';
    e.name = obj.name !== undefined ? obj.name : '';
    e.targetDate = obj.targetDate !== undefined ? obj.targetDate : '';
    e.category = obj.category !== undefined && obj.category.length > 0 ? obj.category : 'other';
    e.note = obj.note !== undefined ? obj.note : '';
    e.repeatYearly = obj.repeatYearly === true;
    e.pinned = obj.pinned === true;
    e.createdAt = obj.createdAt !== undefined ? obj.createdAt : 0;
    e.remindMode = obj.remindMode !== undefined ? obj.remindMode : 0;
    e.reminderId = obj.reminderId !== undefined ? obj.reminderId : 0;
    if (obj.items !== undefined && Array.isArray(obj.items)) {
      e.items = obj.items.map((it: ChecklistItem): ChecklistItem => {
        const c: ChecklistItem = { text: it.text, done: it.done === true };
        return c;
      });
    }
    e.background = obj.background !== undefined ? obj.background : '';
    return e;
  }
}

/**
 * 计算目标日期距今的天数（正数=未来还有X天，负数=已过X天，0=今天）
 */
export function daysBetween(targetDate: string): number {
  const target = new Date(targetDate + 'T00:00:00');
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diff = target.getTime() - today.getTime();
  return Math.round(diff / 86400000);
}

/**
 * Date 格式化为 yyyy-MM-dd
 */
export function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/**
 * 每年重复的事件：把原始日期滚动到"今天或之后"的下一次发生日期
 * 例：生日 1990-05-20，今天 2026-10-01 → 返回 2027-05-20
 */
export function effectiveDate(item: CountdownEvent): string {
  if (!item.repeatYearly) {
    return item.targetDate;
  }
  const parts = item.targetDate.split('-');
  if (parts.length !== 3) {
    return item.targetDate;
  }
  const month = Number(parts[1]);
  const day = Number(parts[2]);
  if (Number.isNaN(month) || Number.isNaN(day)) {
    return item.targetDate;
  }
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let candidate = new Date(today.getFullYear(), month - 1, day);
  if (candidate.getTime() < today.getTime()) {
    candidate = new Date(today.getFullYear() + 1, month - 1, day);
  }
  return formatDate(candidate);
}

/**
 * 距离这次发生的天数（考虑每年重复）
 */
export function daysToEvent(item: CountdownEvent): number {
  return daysBetween(effectiveDate(item));
}

// ==================== 里程碑时间轴 ====================

export interface Milestone {
  label: string;        // 如 '100 天' / '1 周年' / '满 30 岁'
  dateStr: string;      // 到达日 yyyy-MM-dd
  daysFromToday: number; // 距今天数，负数=已达成
  daysFromBase: number;  // 距事件原始日期的天数
}

// 固定的天数里程碑节点
const MILESTONE_DAYS: number[] = [30, 100, 200, 365, 500, 1000, 1500, 2000, 3000, 5000, 10000];

/**
 * 距原始日期已过的天数（正数=已过 X 天）
 */
export function elapsedDays(item: CountdownEvent): number {
  return -daysBetween(item.targetDate);
}

/**
 * 生成事件的里程碑列表（按到达日期升序，去重）
 * 生日分类显示"满 N 岁"，其余显示"N 周年"
 */
export function milestoneList(item: CountdownEvent): Milestone[] {
  const parts = item.targetDate.split('-');
  if (parts.length !== 3) {
    return [];
  }
  const y = Number(parts[0]);
  const m = Number(parts[1]);
  const d = Number(parts[2]);
  if (Number.isNaN(y) || Number.isNaN(m) || Number.isNaN(d)) {
    return [];
  }
  const base = new Date(y, m - 1, d);
  const isBirthday = item.category === 'birthday';
  const list: Milestone[] = [];
  const seen = new Set<string>();

  const push = (label: string, date: Date): void => {
    const ds = formatDate(date);
    if (seen.has(ds)) {
      return;
    }
    seen.add(ds);
    const fromToday = daysBetween(ds);
    const fromBase = Math.round((date.getTime() - base.getTime()) / 86400000);
    const ms: Milestone = { label: label, dateStr: ds, daysFromToday: fromToday, daysFromBase: fromBase };
    list.push(ms);
  };

  for (const days of MILESTONE_DAYS) {
    const date = new Date(base.getTime() + days * 86400000);
    let label = `${days} 天`;
    if (days === 365) {
      label = isBirthday ? '满 1 岁' : '1 周年';
    }
    push(label, date);
  }
  for (let k = 1; k <= 40; k++) {
    const date = new Date(y + k, m - 1, d);
    const label = isBirthday ? `满 ${k} 岁` : `${k} 周年`;
    push(label, date);
  }

  list.sort((a: Milestone, b: Milestone) => a.dateStr.localeCompare(b.dateStr));
  return list;
}

/**
 * 下一个（未达成的）里程碑；全部达成时返回 undefined
 */
export function nextMilestone(item: CountdownEvent): Milestone | undefined {
  return milestoneList(item).find((ms: Milestone) => ms.daysFromToday >= 0);
}

/**
 * 最近一个已达成的里程碑；无则返回 undefined
 */
export function lastMilestone(item: CountdownEvent): Milestone | undefined {
  const passed = milestoneList(item).filter((ms: Milestone) => ms.daysFromToday < 0);
  return passed.length > 0 ? passed[passed.length - 1] : undefined;
}

/**
 * 从上一个里程碑到下一个里程碑的进度（0~100）
 */
export function milestoneProgress(item: CountdownEvent): number {
  const next = nextMilestone(item);
  const last = lastMilestone(item);
  if (next === undefined) {
    return 100;
  }
  const lastBase = last !== undefined ? last.daysFromBase : 0;
  const span = next.daysFromBase - lastBase;
  if (span <= 0) {
    return 100;
  }
  const elapsed = elapsedDays(item);
  return Math.min(100, Math.max(0, Math.round(((elapsed - lastBase) / span) * 100)));
}

// ==================== 多单位换算与日期计算器 ====================

/**
 * 两日期之间的工作日数量（周一~周五，不含起始日、含结束日；方向自动适应正负）
 */
export function workingDaysBetween(fromDate: string, toDate: string): number {
  const a = new Date(fromDate + 'T00:00:00');
  const b = new Date(toDate + 'T00:00:00');
  if (Number.isNaN(a.getTime()) || Number.isNaN(b.getTime())) {
    return 0;
  }
  const forward = b.getTime() >= a.getTime();
  const step = forward ? 86400000 : -86400000;
  let cursor = a.getTime() + step;
  const end = b.getTime();
  let count = 0;
  let guard = 0;
  while ((forward ? cursor <= end : cursor >= end) && guard < 50000) {
    const dow = new Date(cursor).getDay();
    if (dow !== 0 && dow !== 6) {
      count++;
    }
    cursor += step;
    guard++;
  }
  return count;
}

/**
 * 详情页多单位描述：周数、总小时数、工作日
 */
export function unitBreakdown(item: CountdownEvent): string {
  const d = daysToEvent(item);
  if (d === 0) {
    return '就是今天';
  }
  const abs = Math.abs(d);
  const weeks = Math.floor(abs / 7);
  const hours = abs * 24;
  const ref = d > 0 ? formatDate(new Date()) : item.targetDate;
  const target = d > 0 ? effectiveDate(item) : formatDate(new Date());
  const wd = workingDaysBetween(ref, target);
  let line = '';
  if (d > 0) {
    line = `还有 ${abs} 天`;
  } else {
    line = `已过 ${abs} 天`;
  }
  if (weeks >= 1) {
    line += ` · 约 ${weeks} 周`;
  }
  line += ` · 约 ${hours} 小时`;
  if (wd > 0) {
    line += ` · ${wd} 个工作日`;
  }
  return line;
}
