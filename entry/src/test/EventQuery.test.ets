import { describe, it, expect } from '@ohos/hypium';
import { CountdownEvent, ChecklistItem, formatDate } from '../main/ets/model/CountdownEvent';
import {
  filterAndSort,
  summaryText,
  dateLine,
  computeStats,
  EventStats,
  doneCount,
  checklistLabel,
  lastMilestoneText,
  nextMilestoneText,
  showMilestones,
  badgeColor,
  todayMemories
} from '../main/ets/model/EventQuery';

function today0(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function isoShift(days: number): string {
  const d = new Date(today0().getTime() + days * 86400000);
  return formatDate(new Date(d.getFullYear(), d.getMonth(), d.getDate()));
}

function ev(id: string, name: string, days: number, category: string): CountdownEvent {
  const e = new CountdownEvent();
  e.id = id;
  e.name = name;
  e.targetDate = isoShift(days);
  e.category = category;
  e.createdAt = 1000 + days;
  return e;
}

export default function eventQueryTest() {
  describe('EventQuery.filterAndSort', () => {
    it('按分类过滤', 0, () => {
      const list = [ev('1', '生日', 3, 'birthday'), ev('2', '考试', 5, 'work'), ev('3', '纪念', 9, 'anniversary')];
      const birthdays = filterAndSort(list, 'birthday', '', 'date');
      expect(birthdays.length).assertEqual(1);
      expect(birthdays[0].id).assertEqual('1');
    });

    it('all 不过滤', 0, () => {
      const list = [ev('1', 'a', 3, 'birthday'), ev('2', 'b', 5, 'work')];
      expect(filterAndSort(list, 'all', '', 'date').length).assertEqual(2);
    });

    it('关键字匹配名称与备注且忽略大小写', 0, () => {
      const a = ev('1', 'Trip To Japan', 3, 'other');
      const b = ev('2', '考试', 5, 'work');
      b.note = '带 trip 资料';
      const c = ev('3', '无关', 7, 'other');
      const result = filterAndSort([a, b, c], 'all', '  TRIP ', 'date');
      expect(result.length).assertEqual(2);
    });

    it('关键字为空串不过滤', 0, () => {
      const list = [ev('1', 'a', 3, 'other'), ev('2', 'b', 5, 'other')];
      expect(filterAndSort(list, 'all', '   ', 'date').length).assertEqual(2);
    });

    it('置顶优先，其次按剩余天数', 0, () => {
      const far = ev('1', '远', 30, 'other');
      const near = ev('2', '近', 1, 'other');
      const pinnedFar = ev('3', '置顶', 60, 'other');
      pinnedFar.pinned = true;
      const result = filterAndSort([far, near, pinnedFar], 'all', '', 'date');
      expect(result[0].id).assertEqual('3');
      expect(result[1].id).assertEqual('2');
      expect(result[2].id).assertEqual('1');
    });

    it('按添加时间倒序排序', 0, () => {
      const oldOne = ev('1', '早', 30, 'other');
      oldOne.createdAt = 1000;
      const newOne = ev('2', '晚', 1, 'other');
      newOne.createdAt = 9000;
      const result = filterAndSort([oldOne, newOne], 'all', '', 'created');
      expect(result[0].id).assertEqual('2');
    });

    it('不修改原数组', 0, () => {
      const list = [ev('1', 'a', 30, 'other'), ev('2', 'b', 1, 'other')];
      filterAndSort(list, 'all', '', 'date');
      expect(list[0].id).assertEqual('1');
    });
  });

  describe('EventQuery.summaryText', () => {
    it('空列表给出引导文案', 0, () => {
      expect(summaryText([])).assertEqual('开始记录第一个重要日子');
    });

    it('给出最近的一个日子', 0, () => {
      const line = summaryText([ev('1', '远行', 30, 'other'), ev('2', '考试', 2, 'work')]);
      expect(line).assertContain('共 2 个日子');
      expect(line).assertContain('最近「考试」');
      expect(line).assertContain('2 天后');
    });

    it('今天用"就是今天"', 0, () => {
      expect(summaryText([ev('1', '生日', 0, 'birthday')])).assertContain('就是今天');
    });

    it('已经过去的日子用"N 天前"', 0, () => {
      expect(summaryText([ev('1', '旧事', -5, 'other')])).assertContain('5 天前');
    });
  });

  describe('EventQuery.dateLine', () => {
    it('基础信息只含日期与分类', 0, () => {
      const e = ev('1', '生日', 3, 'birthday');
      expect(dateLine(e)).assertEqual(`${e.targetDate} · 生日`);
    });

    it('含每年与提醒标记', 0, () => {
      const e = ev('1', '生日', 3, 'birthday');
      e.repeatYearly = true;
      e.remindMode = 1;
      const line = dateLine(e);
      expect(line).assertContain('· 每年');
      expect(line).assertContain('🔔');
    });
  });

  describe('EventQuery.computeStats', () => {
    it('区分进行中/30天内/已过期/提醒/置顶', 0, () => {
      const a = ev('1', 'a', 0, 'other');
      const b = ev('2', 'b', 10, 'other');
      b.remindMode = 1;
      const c = ev('3', 'c', 40, 'other');
      c.pinned = true;
      const d = ev('4', 'd', -3, 'other');
      const stats: EventStats = computeStats([a, b, c, d]);
      expect(stats.total).assertEqual(4);
      expect(stats.ongoing).assertEqual(3);
      expect(stats.within30).assertEqual(2);
      expect(stats.overdue).assertEqual(1);
      expect(stats.withReminder).assertEqual(1);
      expect(stats.pinned).assertEqual(1);
    });

    it('空列表全为 0', 0, () => {
      const stats = computeStats([]);
      expect(stats.total).assertEqual(0);
      expect(stats.ongoing).assertEqual(0);
    });
  });

  describe('EventQuery.清单进度', () => {
    it('统计已完成条目', 0, () => {
      const items: ChecklistItem[] = [
        { text: 'a', done: true },
        { text: 'b', done: false },
        { text: 'c', done: true }
      ];
      expect(doneCount(items)).assertEqual(2);
      expect(checklistLabel(items)).assertEqual('准备 2/3');
    });

    it('空清单', 0, () => {
      expect(doneCount([])).assertEqual(0);
      expect(checklistLabel([])).assertEqual('准备 0/0');
    });
  });

  describe('EventQuery.里程碑文案', () => {
    it('已开始计时的日子显示里程碑区块', 0, () => {
      expect(showMilestones(ev('1', '恋爱', -100, 'anniversary'))).assertTrue();
      expect(showMilestones(ev('2', '未来', 10, 'anniversary'))).assertFalse();
    });

    it('已达成与下一个里程碑文案', 0, () => {
      const item = ev('1', '恋爱', -150, 'anniversary');
      expect(lastMilestoneText(item)).assertEqual('已达成「100 天」');
      const next = nextMilestoneText(item);
      expect(next).assertContain('下一个：200 天');
      expect(next).assertContain('天后');
    });

    it('刚好今天达成的里程碑文案', 0, () => {
      const item = ev('1', '恋爱', -100, 'anniversary');
      expect(nextMilestoneText(item)).assertContain('就是今天');
    });

    it('没有里程碑时文案为空', 0, () => {
      expect(nextMilestoneText(ev('1', '很久', -30000, 'anniversary'))).assertEqual('');
      expect(lastMilestoneText(ev('2', '未来', 100, 'anniversary'))).assertEqual('');
    });
  });

  describe('EventQuery.badgeColor', () => {
    it('按天数区间取色', 0, () => {
      expect(badgeColor(-1)).assertEqual('#666666');
      expect(badgeColor(0)).assertEqual('#A32D2D');
      expect(badgeColor(1)).assertEqual('#C0392B');
      expect(badgeColor(7)).assertEqual('#C0392B');
      expect(badgeColor(8)).assertEqual('#8F5A00');
      expect(badgeColor(30)).assertEqual('#8F5A00');
      expect(badgeColor(31)).assertEqual('#185FA5');
    });
  });

  describe('EventQuery.todayMemories', () => {
    it('命中去年的今天', 0, () => {
      const t = today0();
      const md = `${(t.getMonth() + 1).toString().padStart(2, '0')}-${t.getDate().toString().padStart(2, '0')}`;
      const past = new CountdownEvent();
      past.id = 'm1';
      past.targetDate = `${t.getFullYear() - 1}-${md}`;
      const future = new CountdownEvent();
      future.id = 'm2';
      future.targetDate = `${t.getFullYear() + 1}-${md}`;
      const other = new CountdownEvent();
      other.id = 'm3';
      other.targetDate = `${t.getFullYear() - 2}-01-${t.getDate() === 15 ? '16' : '15'}`.substring(0, 10);
      const result = todayMemories([past, future, other], t);
      expect(result.length).assertEqual(1);
      expect(result[0].id).assertEqual('m1');
    });

    it('日期字段异常的事件被忽略', 0, () => {
      const broken = new CountdownEvent();
      broken.id = 'x';
      broken.targetDate = '2020-1-1';
      expect(todayMemories([broken], today0()).length).assertEqual(0);
    });
  });
}
