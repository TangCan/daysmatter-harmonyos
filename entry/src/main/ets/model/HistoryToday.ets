/**
 * 历史上的今天（v1.3.5 新增）
 * 内置精选历史事件库：科学发现、文化艺术、体育成就与中国重大成就
 * 全部为公开史实的中性陈述，纯本地数据，无网络请求
 */
import { CountdownEvent, optionOf, CategoryOption, daysBetween } from './CountdownEvent';

export interface HistoryEvent {
  md: string;   // 月-日，如 '07-20'
  year: number; // 发生年份（负数表示公元前）
  text: string; // 事件描述
}

export const HISTORY_EVENTS: HistoryEvent[] = [
  // ---------- 一月 ----------
  { md: '01-01', year: 1801, text: '皮亚齐发现第一颗小行星「谷神星」' },
  { md: '01-01', year: 1863, text: '美国总统林肯签署《解放宣言》' },
  { md: '01-01', year: 1995, text: '世界贸易组织正式成立' },
  { md: '01-04', year: 1643, text: '物理学家艾萨克·牛顿出生' },
  { md: '01-07', year: 1610, text: '伽利略发现木星的四颗卫星' },
  { md: '01-10', year: 1863, text: '伦敦大都会铁路通车，成为世界第一条地铁' },
  { md: '01-11', year: 1922, text: '胰岛素首次用于治疗糖尿病' },
  { md: '01-15', year: 1929, text: '民权领袖马丁·路德·金出生' },
  { md: '01-17', year: 1706, text: '本杰明·富兰克林出生' },
  { md: '01-19', year: 1736, text: '改良蒸汽机的詹姆斯·瓦特出生' },
  { md: '01-24', year: 1848, text: '美国萨特磨坊发现金矿，加州淘金热开始' },
  { md: '01-27', year: 1756, text: '音乐家莫扎特出生' },
  { md: '01-29', year: 1886, text: '卡尔·本茨获得世界上第一项汽车发明专利' },
  // ---------- 二月 ----------
  { md: '02-07', year: 1812, text: '作家查尔斯·狄更斯出生' },
  { md: '02-08', year: 1828, text: '科幻先驱儒勒·凡尔纳出生' },
  { md: '02-11', year: 1847, text: '发明家托马斯·爱迪生出生' },
  { md: '02-12', year: 1809, text: '生物学家查尔斯·达尔文出生' },
  { md: '02-14', year: 1876, text: '亚历山大·贝尔提交电话专利申请' },
  { md: '02-15', year: 1564, text: '天文学家伽利略·伽利雷出生' },
  { md: '02-18', year: 1745, text: '电池发明人亚历山德罗·伏特出生' },
  { md: '02-19', year: 1473, text: '天文学家尼古拉·哥白尼出生' },
  { md: '02-26', year: 1802, text: '作家维克多·雨果出生' },
  // ---------- 三月 ----------
  { md: '03-06', year: 1475, text: '艺术大师米开朗基罗出生' },
  { md: '03-10', year: 1876, text: '贝尔完成人类第一次电话通话' },
  { md: '03-14', year: 1879, text: '物理学家阿尔伯特·爱因斯坦出生' },
  { md: '03-25', year: 1655, text: '惠更斯发现土星最大的卫星「泰坦」' },
  { md: '03-30', year: 1853, text: '画家文森特·梵高出生' },
  { md: '03-31', year: 1889, text: '埃菲尔铁塔落成，成为当时世界最高建筑' },
  // ---------- 四月 ----------
  { md: '04-07', year: 1948, text: '世界卫生组织正式成立' },
  { md: '04-09', year: 1865, text: '美国南北战争结束' },
  { md: '04-12', year: 1961, text: '尤里·加加林成为首位进入太空的人类' },
  { md: '04-15', year: 1452, text: '文艺复兴巨匠列奥纳多·达·芬奇出生' },
  { md: '04-16', year: 1889, text: '喜剧大师查理·卓别林出生' },
  { md: '04-18', year: 1906, text: '美国旧金山发生大地震' },
  { md: '04-22', year: 1724, text: '哲学家伊曼努尔·康德出生' },
  { md: '04-23', year: 1564, text: '剧作家威廉·莎士比亚出生，这天也是世界读书日' },
  { md: '04-25', year: 1874, text: '无线电发明人古列尔莫·马可尼出生' },
  { md: '04-27', year: 1791, text: '电报发明人塞缪尔·莫尔斯出生' },
  // ---------- 五月 ----------
  { md: '05-01', year: 1840, text: '世界上第一枚邮票「黑便士」在英国发行' },
  { md: '05-06', year: 1856, text: '心理学家西格蒙德·弗洛伊德出生' },
  { md: '05-07', year: 1840, text: '作曲家彼得·柴可夫斯基出生' },
  { md: '05-10', year: 1869, text: '美国首条横贯大陆铁路正式贯通' },
  { md: '05-11', year: 1904, text: '超现实主义画家萨尔瓦多·达利出生' },
  { md: '05-14', year: 1796, text: '爱德华·詹纳进行人类首次天花疫苗接种' },
  { md: '05-15', year: 1859, text: '物理学家皮埃尔·居里出生' },
  { md: '05-19', year: 1613, text: '中国明代地理学家徐霞客开始出游（徐霞客开游日）' },
  // ---------- 六月 ----------
  { md: '06-10', year: 1904, text: '中国近代著名建筑学家林徽因出生' },
  { md: '06-12', year: 1929, text: '《安妮日记》作者安妮·弗兰克出生' },
  { md: '06-13', year: 1831, text: '物理学家詹姆斯·麦克斯韦出生' },
  { md: '06-18', year: 1815, text: '滑铁卢战役结束拿破仑时代的欧洲格局' },
  { md: '06-25', year: 1903, text: '《一九八四》作者乔治·奥威尔出生' },
  { md: '06-28', year: 1712, text: '启蒙思想家让-雅克·卢梭出生' },
  { md: '06-30', year: 1905, text: '爱因斯坦发表狭义相对论论文' },
  // ---------- 七月 ----------
  { md: '07-11', year: 1405, text: '明代航海家郑和率船队首次下西洋' },
  { md: '07-10', year: 1856, text: '交流电之父尼古拉·特斯拉出生' },
  { md: '07-14', year: 1789, text: '巴黎民众攻占巴士底狱，法国大革命爆发' },
  { md: '07-15', year: 1606, text: '荷兰绘画大师伦勃朗出生' },
  { md: '07-18', year: 1918, text: '纳尔逊·曼德拉出生' },
  { md: '07-20', year: 1969, text: '阿波罗11号登月，人类首次踏上月球' },
  // ---------- 八月 ----------
  { md: '08-05', year: 1850, text: '法国短篇小说大师莫泊桑出生' },
  { md: '08-06', year: 1881, text: '青霉素发现者亚历山大·弗莱明出生' },
  { md: '08-08', year: 1902, text: '量子力学奠基人保罗·狄拉克出生' },
  { md: '08-08', year: 2008, text: '第29届夏季奥运会在北京开幕' },
  { md: '08-15', year: 1769, text: '军事家拿破仑·波拿巴出生' },
  { md: '08-19', year: 1871, text: '飞机发明人之一奥维尔·莱特出生' },
  { md: '08-30', year: 1797, text: '《弗兰肯斯坦》作者玛丽·雪莱出生' },
  // ---------- 九月 ----------
  { md: '09-05', year: 1638, text: '法国国王路易十四出生' },
  { md: '09-09', year: 1828, text: '文学巨匠列夫·托尔斯泰出生' },
  { md: '09-21', year: 1866, text: '科幻作家赫伯特·乔治·威尔斯出生' },
  { md: '09-28', year: -551, text: '中国古代思想家、教育家孔子诞生（传统纪年）' },
  // ---------- 十月 ----------
  { md: '10-01', year: 1949, text: '中华人民共和国成立' },
  { md: '10-02', year: 1869, text: '「圣雄」甘地出生' },
  { md: '10-04', year: 1957, text: '人类第一颗人造卫星「斯普特尼克1号」发射成功' },
  { md: '10-07', year: 1885, text: '量子物理学家尼尔斯·玻尔出生' },
  { md: '10-13', year: 1923, text: '安卡拉被确定为土耳其首都' },
  { md: '10-15', year: 1844, text: '哲学家弗里德里希·尼采出生' },
  { md: '10-15', year: 2003, text: '神舟五号发射，航天员杨利伟进入太空' },
  { md: '10-16', year: 1854, text: '剧作家奥斯卡·王尔德出生' },
  { md: '10-21', year: 1833, text: '诺贝尔奖创始人阿尔弗雷德·诺贝尔出生' },
  { md: '10-22', year: 1811, text: '钢琴之王弗朗茨·李斯特出生' },
  { md: '10-25', year: 1881, text: '画家巴勃罗·毕加索出生' },
  { md: '10-31', year: 1517, text: '马丁·路德张贴《九十五条论纲》，宗教改革开始' },
  // ---------- 十一月 ----------
  { md: '11-07', year: 1867, text: '两获诺贝尔奖的玛丽·居里出生' },
  { md: '11-11', year: 1821, text: '俄国文学大师陀思妥耶夫斯基出生' },
  { md: '11-12', year: 1840, text: '雕塑大师奥古斯特·罗丹出生' },
  { md: '11-13', year: 1850, text: '《金银岛》作者史蒂文森出生' },
  { md: '11-14', year: 1840, text: '印象派绘画大师克劳德·莫奈出生' },
  { md: '11-20', year: 1889, text: '天文学家埃德温·哈勃出生' },
  { md: '11-24', year: 1859, text: '达尔文的《物种起源》正式出版' },
  { md: '11-26', year: 1922, text: '考古学家霍华德·卡特打开图坦卡蒙法老墓' },
  { md: '11-30', year: 1835, text: '幽默文学大师马克·吐温出生' },
  // ---------- 十二月 ----------
  { md: '12-05', year: 1901, text: '迪士尼公司创始人沃尔特·迪士尼出生' },
  { md: '12-09', year: 1608, text: '诗人约翰·弥尔顿出生' },
  { md: '12-10', year: 1830, text: '诗人艾米莉·狄金森出生' },
  { md: '12-10', year: 1896, text: '阿尔弗雷德·诺贝尔逝世，遗嘱设立诺贝尔奖' },
  { md: '12-12', year: 1821, text: '小说家古斯塔夫·福楼拜出生' },
  { md: '12-14', year: 1900, text: '物理学家普朗克提出量子假说' },
  { md: '12-16', year: 1770, text: '乐圣路德维希·范·贝多芬出生（受洗记录）' },
  { md: '12-18', year: 1856, text: '电子发现人约瑟夫·汤姆逊出生' },
  { md: '12-25', year: 1642, text: '艾萨克·牛顿出生（儒略历纪日）' },
  { md: '12-27', year: 1822, text: '微生物学之父路易·巴斯德出生' }
];

function pad2(n: number): string {
  return n.toString().padStart(2, '0');
}

/**
 * Date → 'MM-dd'
 */
export function mdOfDate(d: Date): string {
  return `${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

/**
 * 弹窗标题用的「M月D日」文案
 */
export function historyTitle(d: Date): string {
  return `${d.getMonth() + 1}月${d.getDate()}日`;
}

/**
 * 查询某一天的历史事件（按年份从古至今排序）
 */
export function historyForDate(md: string): HistoryEvent[] {
  if (md.length !== 5 || md.charAt(2) !== '-') {
    return [];
  }
  const list = HISTORY_EVENTS.filter((h: HistoryEvent) => h.md === md);
  list.sort((a: HistoryEvent, b: HistoryEvent) => a.year - b.year);
  return list;
}

/**
 * 事件年份展示文案：公元前用「前 N 年」
 */
export function historyYearText(year: number): string {
  if (year < 0) {
    return `前 ${-year} 年`;
  }
  return `${year} 年`;
}

/**
 * 随机取一条「今天」的历史事件（用于首页点睛展示）
 * seed：任意整数（如事件数），保证同一参数结果稳定可测
 */
export function pickHistoryOf(md: string, seed: number): HistoryEvent | undefined {
  const list = historyForDate(md);
  if (list.length === 0) {
    return undefined;
  }
  const idx = Math.abs(seed) % list.length;
  return list[idx];
}

// ==================== 整合时间轴（v1.3.5）：我的那天 + 历史上的今天 ====================

export interface TodayItem {
  kind: number;   // 0=我的那天（可点击进详情） 1=内置历史事件
  year: number;   // 排序用年份（mine 取 targetDate 前四位）
  title: string;  // mine=事件名 / history=事件描述
  sub: string;    // mine 的语境副标题（分类·每年·N 天前 / 周年 / 满N岁），history 为空
  refId: string;  // mine 的事件 id，点击跳详情用；history 为空串
}

/**
 * 合并「用户在这一天发生的事件」与「内置历史事件」，按年份升序；
 * 同年时我的事件排在前面；今天的（daysBetween=0）与未来事件不算回忆
 */
export function integratedToday(events: CountdownEvent[], md: string, custom: CategoryOption[]): TodayItem[] {
  const items: TodayItem[] = [];

  // 我的那天：原始日期月-日匹配且严格在过去
  const now = new Date();
  for (const e of events) {
    if (e.targetDate.length < 10 || e.targetDate.substring(5) !== md) {
      continue;
    }
    if (daysBetween(e.targetDate) >= 0) {
      continue;
    }
    const y = Number(e.targetDate.substring(0, 4));
    if (Number.isNaN(y) || y <= 0) {
      continue;
    }
    const cat = optionOf(e.category, custom);
    let sub = `${cat.emoji} ${cat.label}`;
    const years = now.getFullYear() - y;
    if (e.repeatYearly && e.category === 'birthday') {
      sub += ` · 满 ${years} 岁的这一天`;
    } else if (e.repeatYearly) {
      sub += ` · ${years} 周年`;
    } else {
      const elapsed = Math.round((now.getTime() - new Date(e.targetDate + 'T00:00:00').getTime()) / 86400000);
      sub += ` · ${elapsed} 天前`;
    }
    const item: TodayItem = { kind: 0, year: y, title: e.name, sub: sub, refId: e.id };
    items.push(item);
  }

  // 内置历史事件
  for (const h of historyForDate(md)) {
    const item: TodayItem = { kind: 1, year: h.year, title: h.text, sub: '', refId: '' };
    items.push(item);
  }

  items.sort((a: TodayItem, b: TodayItem) => {
    if (a.year !== b.year) {
      return a.year - b.year;
    }
    return a.kind - b.kind; // 同年我的在前
  });
  return items;
}
