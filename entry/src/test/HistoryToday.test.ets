import { describe, it, expect } from '@ohos/hypium';
import {
  HISTORY_EVENTS,
  historyForDate,
  historyYearText,
  mdOfDate,
  pickHistoryOf,
  HistoryEvent
} from '../main/ets/model/HistoryToday';

export default function historyTodayTest() {
  describe('HistoryToday.data', () => {
    it('数据集非空且条目结构合法', 0, () => {
      expect(HISTORY_EVENTS.length > 80).assertTrue();
      for (const h of HISTORY_EVENTS) {
        expect(h.md.length).assertEqual(5);
        expect(h.text.length > 0).assertTrue();
        expect(h.year !== 0).assertTrue();
      }
    });

    it('md 格式均为 MM-dd', 0, () => {
      for (const h of HISTORY_EVENTS) {
        const m = Number(h.md.substring(0, 2));
        const d = Number(h.md.substring(3));
        expect(m >= 1 && m <= 12).assertTrue();
        expect(d >= 1 && d <= 31).assertTrue();
        expect(h.md.charAt(2)).assertEqual('-');
      }
    });

    it('重大节点存在：登月 / 中华人民共和国成立 / 北京奥运', 0, () => {
      let hasMoon = false;
      let hasPRC = false;
      let hasOlympics = false;
      for (const h of HISTORY_EVENTS) {
        if (h.md === '07-20' && h.year === 1969) {
          hasMoon = true;
        }
        if (h.md === '10-01' && h.year === 1949) {
          hasPRC = true;
        }
        if (h.md === '08-08' && h.year === 2008) {
          hasOlympics = true;
        }
      }
      expect(hasMoon).assertTrue();
      expect(hasPRC).assertTrue();
      expect(hasOlympics).assertTrue();
    });
  });

  describe('HistoryToday.query', () => {
    it('按日期命中并按年份升序', 0, () => {
      const list = historyForDate('11-07');
      expect(list.length).assertEqual(1);
      expect(list[0].year).assertEqual(1867);
      expect(list[0].text.indexOf('居里') >= 0).assertTrue();
    });

    it('同年多条按年份排序（01-01 有 3 条）', 0, () => {
      const list = historyForDate('01-01');
      expect(list.length).assertEqual(3);
      expect(list[0].year).assertEqual(1801);
      expect(list[2].year).assertEqual(1995);
    });

    it('无收录日期返回空数组', 0, () => {
      expect(historyForDate('02-30').length).assertEqual(0);
    });

    it('非法输入返回空数组', 0, () => {
      expect(historyForDate('').length).assertEqual(0);
      expect(historyForDate('1107').length).assertEqual(0);
      expect(historyForDate('11/07').length).assertEqual(0);
    });

    it('mdOfDate 输出 MM-dd', 0, () => {
      const d = new Date(2026, 0, 5);
      expect(mdOfDate(d)).assertEqual('01-05');
      const d2 = new Date(2026, 11, 31);
      expect(mdOfDate(d2)).assertEqual('12-31');
    });

    it('公元前年份展示为「前 N 年」', 0, () => {
      expect(historyYearText(1969)).assertEqual('1969 年');
      expect(historyYearText(-551)).assertEqual('前 551 年');
    });

    it('pickHistoryOf 稳定取值且越界安全', 0, () => {
      const a = pickHistoryOf('11-07', 0);
      const b = pickHistoryOf('11-07', 7);
      expect(a !== undefined).assertTrue();
      expect(b !== undefined).assertTrue();
      if (a !== undefined && b !== undefined) {
        expect(a.year).assertEqual(b.year);
      }
      expect(pickHistoryOf('02-30', 1) === undefined).assertTrue();
    });
  });
}
