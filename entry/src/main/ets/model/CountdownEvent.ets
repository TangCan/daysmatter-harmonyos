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

export class CountdownEvent {
  id: string = '';
  name: string = '';
  targetDate: string = ''; // 格式 yyyy-MM-dd；开启每年重复时允许是过去的原始日期
  category: string = 'other';
  note: string = '';
  repeatYearly: boolean = false;
  pinned: boolean = false;
  createdAt: number = 0;

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
