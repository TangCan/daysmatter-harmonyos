/**
 * 事件查询 / 展示文案（纯函数，不依赖任何系统能力，便于单元测试）
 * 从 Index 页面抽离，保证 UI 与逻辑分离
 */
import {
  CountdownEvent,
  ChecklistItem,
  Milestone,
  daysToEvent,
  daysBetween,
  categoryOption,
  elapsedDays,
  lastMilestone,
  nextMilestone
} from './CountdownEvent';

export interface EventStats {
  total: number;
  ongoing: number;
  within30: number;
  overdue: number;
  withReminder: number;
  pinned: number;
}

/**
 * 过滤 + 排序：置顶优先，其次按日期升序或按添加时间倒序
 */
export function filterAndSort(events: CountdownEvent[], filter: string, keyword: string, sortBy: string): CountdownEvent[] {
  let list: CountdownEvent[] = events;
  if (filter !== 'all') {
    list = list.filter((e: CountdownEvent) => e.category === filter);
  }
  const kw = keyword.trim().toLowerCase();
  if (kw.length > 0) {
    list = list.filter((e: CountdownEvent) =>
      e.name.toLowerCase().includes(kw) || e.note.toLowerCase().includes(kw));
  }
  const result = list.slice();
  result.sort((a: CountdownEvent, b: CountdownEvent) => {
    if (a.pinned !== b.pinned) {
      return a.pinned ? -1 : 1;
    }
    if (sortBy === 'created') {
      return b.createdAt - a.createdAt;
    }
    return daysToEvent(a) - daysToEvent(b);
  });
  return result;
}

/**
 * 顶部摘要：共 N 个日子 · 最近「xxx」N 天后
 */
export function summaryText(events: CountdownEvent[]): string {
  if (events.length === 0) {
    return '开始记录第一个重要日子';
  }
  let bestName = events[0].name;
  let bestDays = daysToEvent(events[0]);
  for (const e of events) {
    const d = daysToEvent(e);
    if (d < bestDays) {
      bestDays = d;
      bestName = e.name;
    }
  }
  let tail = '';
  if (bestDays === 0) {
    tail = '就是今天';
  } else if (bestDays > 0) {
    tail = `${bestDays} 天后`;
  } else {
    tail = `${-bestDays} 天前`;
  }
  return `共 ${events.length} 个日子 · 最近「${bestName}」${tail}`;
}

/**
 * 卡片日期行：yyyy-MM-dd · 分类 · 每年 · 提醒标记
 */
export function dateLine(item: CountdownEvent): string {
  const cat = categoryOption(item.category).label;
  let line = `${item.targetDate} · ${cat}`;
  if (item.repeatYearly) {
    line += ' · 每年';
  }
  if (item.remindMode > 0) {
    line += ' · 🔔';
  }
  return line;
}

/**
 * 数据概览统计
 */
export function computeStats(events: CountdownEvent[]): EventStats {
  let ongoing = 0;
  let within30 = 0;
  let overdue = 0;
  let withReminder = 0;
  let pinned = 0;
  for (const e of events) {
    const d = daysToEvent(e);
    if (d >= 0) {
      ongoing++;
      if (d <= 30) {
        within30++;
      }
    } else {
      overdue++;
    }
    if (e.remindMode > 0) {
      withReminder++;
    }
    if (e.pinned) {
      pinned++;
    }
  }
  const stats: EventStats = {
    total: events.length,
    ongoing: ongoing,
    within30: within30,
    overdue: overdue,
    withReminder: withReminder,
    pinned: pinned
  };
  return stats;
}

/**
 * 清单已完成数量
 */
export function doneCount(items: ChecklistItem[]): number {
  return items.filter((it: ChecklistItem) => it.done).length;
}

/**
 * 清单进度文案：准备 1/2
 */
export function checklistLabel(items: ChecklistItem[]): string {
  return `准备 ${doneCount(items)}/${items.length}`;
}

/**
 * 已达成里程碑文案
 */
export function lastMilestoneText(item: CountdownEvent): string {
  const ms: Milestone | undefined = lastMilestone(item);
  return ms !== undefined ? `已达成「${ms.label}」` : '';
}

/**
 * 下一个里程碑文案
 */
export function nextMilestoneText(item: CountdownEvent): string {
  const ms: Milestone | undefined = nextMilestone(item);
  if (ms === undefined) {
    return '';
  }
  const when = ms.daysFromToday === 0 ? '就是今天' : `${ms.daysFromToday} 天后`;
  return `下一个：${ms.label} · ${ms.dateStr}（${when}）`;
}

/**
 * 是否需要展示里程碑区块（已开始计时的日子才展示）
 */
export function showMilestones(item: CountdownEvent): boolean {
  return elapsedDays(item) > 0;
}

/**
 * 天数徽标配色（红→橙→蓝，已过为灰）
 */
export function badgeColor(days: number): string {
  if (days < 0) {
    return '#666666';
  } else if (days === 0) {
    return '#A32D2D';
  } else if (days <= 7) {
    return '#C0392B';
  } else if (days <= 30) {
    return '#8F5A00';
  }
  return '#185FA5';
}

function pad2(n: number): string {
  return n.toString().padStart(2, '0');
}

/**
 * 那年今天：历史上同月同日且已经过去的事件
 */
export function todayMemories(events: CountdownEvent[], now: Date): CountdownEvent[] {
  const md = `${pad2(now.getMonth() + 1)}-${pad2(now.getDate())}`;
  return events.filter((e: CountdownEvent) => {
    return e.targetDate.length >= 10 && e.targetDate.substring(5) === md && daysBetween(e.targetDate) < 0;
  });
}
