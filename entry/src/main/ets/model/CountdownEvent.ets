/**
 * 倒数日数据模型
 */
export class CountdownEvent {
  id: string = '';
  name: string = '';
  targetDate: string = ''; // 格式 yyyy-MM-dd

  static fromJson(obj: CountdownEvent): CountdownEvent {
    const e = new CountdownEvent();
    e.id = obj.id;
    e.name = obj.name;
    e.targetDate = obj.targetDate;
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
