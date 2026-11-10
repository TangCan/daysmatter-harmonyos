import { describe, it, expect } from '@ohos/hypium';
import { DateSelection, daysInMonth, stepSelection, calcDateRange, MIN_YEAR, MAX_YEAR } from '../main/ets/model/DateStepper';

function sel(year: number, month: number, day: number): DateSelection {
  const s: DateSelection = { year: year, month: month, day: day };
  return s;
}

function today0(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

export default function dateStepperTest() {
  describe('DateStepper.daysInMonth', () => {
    it('平年与闰年二月', 0, () => {
      expect(daysInMonth(2024, 2)).assertEqual(29);
      expect(daysInMonth(2025, 2)).assertEqual(28);
      expect(daysInMonth(2100, 2)).assertEqual(28);
    });

    it('大小月', 0, () => {
      expect(daysInMonth(2026, 4)).assertEqual(30);
      expect(daysInMonth(2026, 12)).assertEqual(31);
      expect(daysInMonth(2026, 1)).assertEqual(31);
    });
  });

  describe('DateStepper.stepSelection', () => {
    it('年步进', 0, () => {
      const next = stepSelection(sel(2030, 5, 20), '年', 1, true, today0()) as DateSelection;
      expect(next.year).assertEqual(2031);
      expect(next.month).assertEqual(5);
      expect(next.day).assertEqual(20);
      const prev = stepSelection(sel(2030, 5, 20), '年', -1, true, today0()) as DateSelection;
      expect(prev.year).assertEqual(2029);
    });

    it('年步进超出范围返回 undefined', 0, () => {
      expect(stepSelection(sel(MIN_YEAR, 1, 1), '年', -1, true, today0()) === undefined).assertTrue();
      expect(stepSelection(sel(MAX_YEAR, 1, 1), '年', 1, true, today0()) === undefined).assertTrue();
    });

    it('月步进跨年', 0, () => {
      const forward = stepSelection(sel(2030, 12, 10), '月', 1, true, today0()) as DateSelection;
      expect(forward.year).assertEqual(2031);
      expect(forward.month).assertEqual(1);
      const backward = stepSelection(sel(2030, 1, 10), '月', -1, true, today0()) as DateSelection;
      expect(backward.year).assertEqual(2029);
      expect(backward.month).assertEqual(12);
    });

    it('月步进后日期按新月份收敛', 0, () => {
      const next = stepSelection(sel(2030, 3, 31), '月', 1, true, today0()) as DateSelection;
      expect(next.month).assertEqual(4);
      expect(next.day).assertEqual(30);
    });

    it('日步进跨月', 0, () => {
      const next = stepSelection(sel(2030, 1, 31), '日', 1, true, today0()) as DateSelection;
      expect(next.month).assertEqual(2);
      expect(next.day).assertEqual(1);
    });

    it('日步进跨年', 0, () => {
      const next = stepSelection(sel(2030, 12, 31), '日', 1, true, today0()) as DateSelection;
      expect(next.year).assertEqual(2031);
      expect(next.month).assertEqual(1);
      expect(next.day).assertEqual(1);
    });

    it('日回退取上月末日', 0, () => {
      const leap = stepSelection(sel(2028, 3, 1), '日', -1, true, today0()) as DateSelection;
      expect(leap.month).assertEqual(2);
      expect(leap.day).assertEqual(29);
      const normal = stepSelection(sel(2029, 3, 1), '日', -1, true, today0()) as DateSelection;
      expect(normal.day).assertEqual(28);
      const crossYear = stepSelection(sel(2029, 1, 1), '日', -1, true, today0()) as DateSelection;
      expect(crossYear.year).assertEqual(2028);
      expect(crossYear.month).assertEqual(12);
      expect(crossYear.day).assertEqual(31);
    });

    it('一次性事件不允许回到过去', 0, () => {
      const today = today0();
      const cur = sel(today.getFullYear(), today.getMonth() + 1, today.getDate());
      expect(stepSelection(cur, '日', -1, false, today) === undefined).assertTrue();
    });

    it('每年重复事件允许保留过去的日期', 0, () => {
      const today = today0();
      const cur = sel(today.getFullYear(), today.getMonth() + 1, today.getDate());
      const prev = stepSelection(cur, '日', -1, true, today) as DateSelection;
      expect(prev.day).assertLarger(0);
      expect(prev.year).assertEqual(today.getFullYear());
    });
  });

  describe('DateStepper.calcDateRange', () => {
    it('正序区间', 0, () => {
      const line = calcDateRange('2026-05-20', '2026-10-01', '');
      expect(line).assertContain('间隔 134 天');
      expect(line).assertContain('个工作日');
      expect(line.indexOf('天 =')).assertEqual(-1);
    });

    it('倒序区间提示结束早于开始', 0, () => {
      const line = calcDateRange('2026-10-01', '2026-05-20', '');
      expect(line).assertContain('结束早于开始');
    });

    it('叠加天数推算', 0, () => {
      const line = calcDateRange('2026-05-20', '2026-05-20', '30');
      expect(line).assertContain('2026-05-20 +30 天 = 2026-06-19');
      const back = calcDateRange('2026-05-20', '2026-05-20', '-20');
      expect(back).assertContain('-20 天 = 2026-04-30');
    });

    it('非法日期给出提示', 0, () => {
      expect(calcDateRange('bad', '2026-05-20', '')).assertEqual('请输入有效日期（格式 yyyy-MM-dd）');
    });

    it('天数为空或非数字时不追加推算', 0, () => {
      expect(calcDateRange('2026-05-20', '2026-05-21', 'abc').indexOf('天 =')).assertEqual(-1);
      expect(calcDateRange('2026-05-20', '2026-05-21', '  ').indexOf('天 =')).assertEqual(-1);
    });
  });
}
