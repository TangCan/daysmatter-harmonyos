/**
 * 节日 / 场景模板库
 * - 固定公历节日：month/day 固定，每年重复
 * - 农历节日：无内置农历算法，内置 2026~2028 公历日期对照表（数据来源：多源交叉核实），
 *   超出对照表年份时退化为"按最后一个已知日期的月/日每年重复"（近似）
 * - 场景模板：仅填充名称/分类/重复开关，日期由用户自选
 */

export interface DayTemplate {
  key: string;
  name: string;
  emoji: string;
  category: string;
  repeatYearly: boolean;
  month: number;           // 0 = 无固定日期（场景模板）
  day: number;
  lunarDates: string[];    // 农历节日的未来公历日期表（yyyy-MM-dd 升序）
}

export const DAY_TEMPLATES: DayTemplate[] = [
  // ---------- 固定公历节日 ----------
  { key: 'yuandan', name: '元旦', emoji: '🎊', category: 'festival', repeatYearly: true, month: 1, day: 1, lunarDates: [] },
  { key: 'qingren', name: '情人节', emoji: '💕', category: 'festival', repeatYearly: true, month: 2, day: 14, lunarDates: [] },
  { key: 'funv', name: '妇女节', emoji: '🌷', category: 'festival', repeatYearly: true, month: 3, day: 8, lunarDates: [] },
  { key: 'laodong', name: '劳动节', emoji: '🔨', category: 'festival', repeatYearly: true, month: 5, day: 1, lunarDates: [] },
  { key: 'ertong', name: '儿童节', emoji: '🎈', category: 'festival', repeatYearly: true, month: 6, day: 1, lunarDates: [] },
  { key: 'jiaoshi', name: '教师节', emoji: '📖', category: 'festival', repeatYearly: true, month: 9, day: 10, lunarDates: [] },
  { key: 'guoqing', name: '国庆节', emoji: '🇨🇳', category: 'festival', repeatYearly: true, month: 10, day: 1, lunarDates: [] },
  { key: 'pinganye', name: '平安夜', emoji: '🍎', category: 'festival', repeatYearly: true, month: 12, day: 24, lunarDates: [] },
  { key: 'shengdan', name: '圣诞节', emoji: '🎄', category: 'festival', repeatYearly: true, month: 12, day: 25, lunarDates: [] },
  { key: 'kuanyue', name: '跨年夜', emoji: '🎆', category: 'festival', repeatYearly: true, month: 12, day: 31, lunarDates: [] },
  // ---------- 农历节日（2026~2028 公历对照） ----------
  { key: 'chunjie', name: '春节', emoji: '🧧', category: 'festival', repeatYearly: true, month: 0, day: 0,
    lunarDates: ['2026-02-17', '2027-02-06', '2028-01-26'] },
  { key: 'yuanxiao', name: '元宵节', emoji: '🏮', category: 'festival', repeatYearly: true, month: 0, day: 0,
    lunarDates: ['2026-03-03', '2027-02-20', '2028-02-09'] },
  { key: 'duanwu', name: '端午节', emoji: '🥟', category: 'festival', repeatYearly: true, month: 0, day: 0,
    lunarDates: ['2026-06-19', '2027-06-09', '2028-05-28'] },
  { key: 'qixi', name: '七夕节', emoji: '💞', category: 'festival', repeatYearly: true, month: 0, day: 0,
    lunarDates: ['2026-08-19', '2027-08-08', '2028-08-26'] },
  { key: 'zhongqiu', name: '中秋节', emoji: '🥮', category: 'festival', repeatYearly: true, month: 0, day: 0,
    lunarDates: ['2026-09-25', '2027-09-15', '2028-10-03'] },
  { key: 'chongyang', name: '重阳节', emoji: '⛰️', category: 'festival', repeatYearly: true, month: 0, day: 0,
    lunarDates: ['2026-10-18', '2027-10-08', '2028-10-26'] },
  // ---------- 场景模板（日期自选） ----------
  { key: 'shengri', name: '生日', emoji: '🎂', category: 'birthday', repeatYearly: true, month: 0, day: 0, lunarDates: [] },
  { key: 'jinian', name: '纪念日', emoji: '💐', category: 'anniversary', repeatYearly: true, month: 0, day: 0, lunarDates: [] },
  { key: 'kaoshi', name: '考试日', emoji: '📝', category: 'work', repeatYearly: false, month: 0, day: 0, lunarDates: [] },
  { key: 'lvxing', name: '旅行出发', emoji: '✈️', category: 'other', repeatYearly: false, month: 0, day: 0, lunarDates: [] },
  { key: 'jiezhige', name: '项目截止', emoji: '⏰', category: 'work', repeatYearly: false, month: 0, day: 0, lunarDates: [] },
  { key: 'huankuan', name: '还款日', emoji: '💳', category: 'other', repeatYearly: false, month: 0, day: 0, lunarDates: [] }
];

/**
 * 解析模板的目标日期：
 * - 固定公历：返回今天或之后的下一次发生日期（yyyy-MM-dd）
 * - 农历节日：取对照表中第一个今天或之后的日期；全部过期时取最后一个日期的月/日（近似）
 * - 场景模板：返回空串（保持用户当前选择的日期）
 */
export function templateTargetDate(t: DayTemplate): string {
  if (t.lunarDates.length > 0) {
    const today = new Date();
    const today0 = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    for (const ds of t.lunarDates) {
      const d = new Date(ds + 'T00:00:00');
      if (d.getTime() >= today0.getTime()) {
        return ds;
      }
    }
    // 对照表年份耗尽：按最后一个已知日期的月/日近似（农历每年漂移，提示用户自行核对）
    const last = t.lunarDates[t.lunarDates.length - 1];
    const parts = last.split('-');
    return `2029-${parts[1]}-${parts[2]}`;
  }
  if (t.month > 0 && t.day > 0) {
    const now = new Date();
    const today0 = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let candidate = new Date(now.getFullYear(), t.month - 1, t.day);
    if (candidate.getTime() < today0.getTime()) {
      candidate = new Date(now.getFullYear() + 1, t.month - 1, t.day);
    }
    const y = candidate.getFullYear();
    const m = (candidate.getMonth() + 1).toString().padStart(2, '0');
    const d = candidate.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
  return '';
}
