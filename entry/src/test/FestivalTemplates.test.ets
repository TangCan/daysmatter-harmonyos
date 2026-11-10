import { describe, it, expect } from '@ohos/hypium';
import { DayTemplate, DAY_TEMPLATES, templateTargetDate } from '../main/ets/common/FestivalTemplates';

function today0(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function findTemplate(key: string): DayTemplate {
  const found = DAY_TEMPLATES.find((t: DayTemplate) => t.key === key) as DayTemplate;
  return found;
}

export default function festivalTemplatesTest() {
  describe('FestivalTemplates.模板库', () => {
    it('模板数量与 key 唯一', 0, () => {
      expect(DAY_TEMPLATES.length).assertEqual(22);
      const keys: string[] = DAY_TEMPLATES.map((t: DayTemplate) => t.key);
      const unique = new Set<string>(keys);
      expect(unique.size).assertEqual(keys.length);
    });

    it('分类与字段合法', 0, () => {
      for (const t of DAY_TEMPLATES) {
        expect(t.name.length > 0).assertTrue();
        expect(t.emoji.length > 0).assertTrue();
        expect(['birthday', 'anniversary', 'festival', 'work', 'other'].indexOf(t.category) >= 0).assertTrue();
      }
    });

    it('农历节日的对照表按日期升序', 0, () => {
      for (const t of DAY_TEMPLATES) {
        if (t.lunarDates.length > 0) {
          for (let i = 1; i < t.lunarDates.length; i++) {
            expect(t.lunarDates[i - 1].localeCompare(t.lunarDates[i]) < 0).assertTrue();
          }
        }
      }
    });
  });

  describe('FestivalTemplates.templateTargetDate', () => {
    it('固定公历节日落在今天或之后', 0, () => {
      const t = findTemplate('guoqing'); // 10-01
      const ds = templateTargetDate(t);
      expect(ds.substring(5)).assertEqual('10-01');
      const d = new Date(ds + 'T00:00:00');
      expect(d.getTime() >= today0().getTime()).assertTrue();
    });

    it('固定公历节日已过则滚到明年', 0, () => {
      const t = findTemplate('yuandan'); // 01-01
      const ds = templateTargetDate(t);
      expect(ds.substring(5)).assertEqual('01-01');
      const d = new Date(ds + 'T00:00:00');
      expect(d.getTime() >= today0().getTime()).assertTrue();
      expect(d.getTime() - today0().getTime() <= 366 * 86400000).assertTrue();
    });

    it('农历节日取对照表中第一个未来日期', 0, () => {
      const t = findTemplate('chunjie');
      const ds = templateTargetDate(t);
      const today = today0();
      const expected = t.lunarDates.find((s: string) => new Date(s + 'T00:00:00').getTime() >= today.getTime());
      if (expected !== undefined) {
        expect(ds).assertEqual(expected);
      } else {
        expect(ds.substring(0, 5)).assertEqual('2029-');
      }
    });

    it('对照表耗尽后按最后已知月日推算 2029 年', 0, () => {
      const t: DayTemplate = {
        key: 'fake-lunar',
        name: '测试农历',
        emoji: '🧪',
        category: 'festival',
        repeatYearly: true,
        month: 0,
        day: 0,
        lunarDates: ['2000-01-01', '2001-02-03']
      };
      expect(templateTargetDate(t)).assertEqual('2029-02-03');
    });

    it('场景模板不改变日期（返回空串）', 0, () => {
      const t = findTemplate('kaoshi');
      expect(templateTargetDate(t)).assertEqual('');
    });

    it('月日缺失时返回空串', 0, () => {
      const t: DayTemplate = {
        key: 'no-date',
        name: '无日期',
        emoji: '❓',
        category: 'other',
        repeatYearly: false,
        month: 0,
        day: 0,
        lunarDates: []
      };
      expect(templateTargetDate(t)).assertEqual('');
    });
  });
}
