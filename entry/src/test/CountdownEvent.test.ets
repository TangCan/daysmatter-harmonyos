import { describe, beforeEach, it, expect } from '@ohos/hypium';
import {
  CountdownEvent,
  ChecklistItem,
  CATEGORY_OPTIONS,
  categoryOption,
  daysBetween,
  formatDate,
  effectiveDate,
  daysToEvent,
  elapsedDays,
  milestoneList,
  Milestone,
  nextMilestone,
  lastMilestone,
  milestoneProgress,
  workingDaysBetween,
  unitBreakdown
} from '../main/ets/model/CountdownEvent';

function today0(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function shiftDays(base: Date, days: number): Date {
  const d = new Date(base.getTime() + days * 86400000);
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function isoShift(days: number): string {
  return formatDate(shiftDays(today0(), days));
}

function makeEvent(dateStr: string, category: string, repeat: boolean): CountdownEvent {
  const e = new CountdownEvent();
  e.id = 'id-' + dateStr;
  e.name = '测试事件';
  e.targetDate = dateStr;
  e.category = category;
  e.repeatYearly = repeat;
  return e;
}

export default function countdownEventTest() {
  describe('CountdownEvent.categoryOption', () => {
    it('已知分类返回对应配置', 0, () => {
      expect(categoryOption('birthday').label).assertEqual('生日');
      expect(categoryOption('anniversary').emoji).assertEqual('💐');
    });

    it('未知分类回退到"其他"', 0, () => {
      expect(categoryOption('unknown-key').key).assertEqual('other');
      expect(categoryOption('').label).assertEqual('其他');
    });

    it('分类配置表结构稳定', 0, () => {
      expect(CATEGORY_OPTIONS.length).assertEqual(5);
      expect(CATEGORY_OPTIONS[0].key).assertEqual('birthday');
    });
  });

  describe('CountdownEvent.fromJson', () => {
    it('完整字段原样还原', 0, () => {
      const raw: CountdownEvent = JSON.parse('{"id":"a1","name":"生日","targetDate":"1990-05-20",' +
        '"category":"birthday","note":"买蛋糕","repeatYearly":true,"pinned":true,"createdAt":123,' +
        '"remindMode":2,"reminderId":9,"background":"/data/bg.jpg",' +
        '"items":[{"text":"订蛋糕","done":true},{"text":"买礼物"}]}');
      const e = CountdownEvent.fromJson(raw);
      expect(e.id).assertEqual('a1');
      expect(e.name).assertEqual('生日');
      expect(e.targetDate).assertEqual('1990-05-20');
      expect(e.category).assertEqual('birthday');
      expect(e.note).assertEqual('买蛋糕');
      expect(e.repeatYearly).assertTrue();
      expect(e.pinned).assertTrue();
      expect(e.createdAt).assertEqual(123);
      expect(e.remindMode).assertEqual(2);
      expect(e.reminderId).assertEqual(9);
      expect(e.background).assertEqual('/data/bg.jpg');
      expect(e.items.length).assertEqual(2);
      expect(e.items[0].done).assertTrue();
      expect(e.items[1].text).assertEqual('买礼物');
      expect(e.items[1].done).assertFalse();
    });

    it('空对象使用默认值', 0, () => {
      const raw: CountdownEvent = JSON.parse('{}');
      const e = CountdownEvent.fromJson(raw);
      expect(e.id).assertEqual('');
      expect(e.category).assertEqual('other');
      expect(e.repeatYearly).assertFalse();
      expect(e.pinned).assertFalse();
      expect(e.createdAt).assertEqual(0);
      expect(e.remindMode).assertEqual(0);
      expect(e.reminderId).assertEqual(0);
      expect(e.background).assertEqual('');
      expect(e.items.length).assertEqual(0);
    });

    it('空字符串分类视为未设置', 0, () => {
      const raw: CountdownEvent = JSON.parse('{"category":""}');
      expect(CountdownEvent.fromJson(raw).category).assertEqual('other');
    });

    it('items 非数组时忽略', 0, () => {
      const raw: CountdownEvent = JSON.parse('{"items":"not-an-array"}');
      expect(CountdownEvent.fromJson(raw).items.length).assertEqual(0);
    });
  });

  describe('CountdownEvent.日期计算', () => {
    it('今天返回 0，明天返回 1，昨天返回 -1', 0, () => {
      expect(daysBetween(isoShift(0))).assertEqual(0);
      expect(daysBetween(isoShift(1))).assertEqual(1);
      expect(daysBetween(isoShift(-1))).assertEqual(-1);
    });

    it('formatDate 补零', 0, () => {
      expect(formatDate(new Date(2026, 0, 5))).assertEqual('2026-01-05');
      expect(formatDate(new Date(2026, 11, 31))).assertEqual('2026-12-31');
    });

    it('不重复的事件返回原始日期', 0, () => {
      const e = makeEvent('2020-01-01', 'other', false);
      expect(effectiveDate(e)).assertEqual('2020-01-01');
      expect(daysToEvent(e)).assertEqual(daysBetween('2020-01-01'));
    });

    it('每年重复：今天当天不滚动到明年', 0, () => {
      const t = today0();
      const md = `${(t.getMonth() + 1).toString().padStart(2, '0')}-${t.getDate().toString().padStart(2, '0')}`;
      const e = makeEvent(`1990-${md}`, 'birthday', true);
      expect(daysToEvent(e)).assertEqual(0);
    });

    it('每年重复：已过的月日滚动到下一年', 0, () => {
      const yesterday = shiftDays(today0(), -1);
      const md = `${(yesterday.getMonth() + 1).toString().padStart(2, '0')}-${yesterday.getDate().toString().padStart(2, '0')}`;
      const e = makeEvent(`1990-${md}`, 'birthday', true);
      const eff = effectiveDate(e);
      expect(eff.substring(5)).assertEqual(md);
      expect(daysToEvent(e)).assertLarger(0);
    });

    it('每年重复：未到的月日留在今年', 0, () => {
      const tomorrow = shiftDays(today0(), 1);
      const md = `${(tomorrow.getMonth() + 1).toString().padStart(2, '0')}-${tomorrow.getDate().toString().padStart(2, '0')}`;
      const e = makeEvent(`1990-${md}`, 'birthday', true);
      expect(daysToEvent(e)).assertEqual(1);
    });

    it('日期格式非法时原样返回', 0, () => {
      const bad = makeEvent('not-a-date', 'other', true);
      expect(effectiveDate(bad)).assertEqual('not-a-date');
      const shortDate = makeEvent('2020-05', 'other', true);
      expect(effectiveDate(shortDate)).assertEqual('2020-05');
      const badMonth = makeEvent('1990-xx-01', 'birthday', true);
      expect(effectiveDate(badMonth)).assertEqual('1990-xx-01');
    });

    it('elapsedDays 过去为正、未来为负', 0, () => {
      expect(elapsedDays(makeEvent(isoShift(-10), 'anniversary', false))).assertEqual(10);
      expect(elapsedDays(makeEvent(isoShift(10), 'anniversary', false))).assertEqual(-10);
    });
  });

  describe('CountdownEvent.milestone', () => {
    it('日期非法时返回空列表', 0, () => {
      expect(milestoneList(makeEvent('2020/01/01', 'other', false)).length).assertEqual(0);
      expect(milestoneList(makeEvent('2020-aa-01', 'other', false)).length).assertEqual(0);
    });

    it('纪念日里程碑包含 30 天与周年标签', 0, () => {
      const list = milestoneList(makeEvent(isoShift(-30), 'anniversary', false));
      expect(list.length).assertLarger(0);
      const thirty = list.filter((m: Milestone) => m.label === '30 天');
      expect(thirty.length).assertEqual(1);
      expect(thirty[0].daysFromToday).assertEqual(0);
      const anniversary = list.filter((m: Milestone) => m.label === '1 周年');
      expect(anniversary.length).assertEqual(1);
    });

    it('生日分类显示满 N 岁', 0, () => {
      const list = milestoneList(makeEvent(isoShift(-365), 'birthday', true));
      const labels = list.map((m: Milestone) => m.label);
      expect(labels.indexOf('满 1 岁') >= 0).assertTrue();
      expect(labels.indexOf('满 40 岁') >= 0).assertTrue();
      expect(labels.indexOf('1 周年') >= 0).assertFalse();
    });

    it('里程碑按日期升序且不重复', 0, () => {
      const list = milestoneList(makeEvent('2025-01-01', 'anniversary', false));
      const seen: string[] = [];
      let sorted = true;
      for (const m of list) {
        if (seen.indexOf(m.dateStr) >= 0) {
          sorted = false;
        }
        seen.push(m.dateStr);
      }
      expect(sorted).assertTrue();
      for (let i = 1; i < list.length; i++) {
        expect(list[i - 1].dateStr.localeCompare(list[i].dateStr) <= 0).assertTrue();
      }
    });

    it('nextMilestone 返回最近的未达成节点', 0, () => {
      const next = nextMilestone(makeEvent(isoShift(-100), 'anniversary', false)) as Milestone;
      expect(next.label).assertEqual('100 天');
      expect(next.daysFromToday).assertEqual(0);
    });

    it('全部达成时 nextMilestone 为空', 0, () => {
      expect(nextMilestone(makeEvent('1950-01-01', 'anniversary', false)) === undefined).assertTrue();
    });

    it('尚未开始时 lastMilestone 为空', 0, () => {
      expect(lastMilestone(makeEvent('2080-01-01', 'anniversary', false)) === undefined).assertTrue();
    });

    it('lastMilestone 返回最近已达成的节点', 0, () => {
      const last = lastMilestone(makeEvent(isoShift(-150), 'anniversary', false)) as Milestone;
      expect(last.label).assertEqual('100 天');
    });

    it('里程碑进度按区间计算', 0, () => {
      // 100 天节点就是今天：进度到顶
      expect(milestoneProgress(makeEvent(isoShift(-100), 'anniversary', false))).assertEqual(100);
      // 上一节点 100 天、下一节点 200 天，已走 150 天 → 50%
      expect(milestoneProgress(makeEvent(isoShift(-150), 'anniversary', false))).assertEqual(50);
      // 上一节点 30 天、下一节点 100 天，已走 45 天 → 约 21%
      expect(milestoneProgress(makeEvent(isoShift(-45), 'anniversary', false))).assertEqual(21);
      // 还没到第一个节点（30 天）时按 0~30 天区间计算
      expect(milestoneProgress(makeEvent(isoShift(-15), 'anniversary', false))).assertEqual(50);
    });

    it('没有下一个里程碑时进度为 100', 0, () => {
      expect(milestoneProgress(makeEvent('1950-01-01', 'anniversary', false))).assertEqual(100);
    });
  });

  describe('CountdownEvent.工作日与多单位', () => {
    it('工作日排除周末', 0, () => {
      // 2026-01-05 周一 → 2026-01-09 周五：不含起始日，共 4 个工作日
      expect(workingDaysBetween('2026-01-05', '2026-01-09')).assertEqual(4);
      // 周五 → 下周一：只算周一
      expect(workingDaysBetween('2026-01-09', '2026-01-12')).assertEqual(1);
    });

    it('倒序区间同样计算', 0, () => {
      expect(workingDaysBetween('2026-01-09', '2026-01-05')).assertEqual(4);
    });

    it('非法日期返回 0', 0, () => {
      expect(workingDaysBetween('abc', '2026-01-05')).assertEqual(0);
      expect(workingDaysBetween('2026-01-05', 'abc')).assertEqual(0);
    });

    it('就是今天', 0, () => {
      expect(unitBreakdown(makeEvent(isoShift(0), 'other', false))).assertEqual('就是今天');
    });

    it('未来的事件给出天数/周数/小时', 0, () => {
      const line = unitBreakdown(makeEvent(isoShift(10), 'other', false));
      expect(line).assertContain('还有 10 天');
      expect(line).assertContain('约 1 周');
      expect(line).assertContain('约 240 小时');
    });

    it('过去的事件给出已过天数', 0, () => {
      const line = unitBreakdown(makeEvent(isoShift(-10), 'other', false));
      expect(line).assertContain('已过 10 天');
      expect(line).assertContain('约 240 小时');
    });

    it('不足一周时不显示周数', 0, () => {
      const line = unitBreakdown(makeEvent(isoShift(1), 'other', false));
      expect(line).assertContain('还有 1 天');
      expect(line.indexOf('周')).assertEqual(-1);
    });
  });
}
