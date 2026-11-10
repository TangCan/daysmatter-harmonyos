import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { CardSync, CardRow } from '../main/ets/common/CardSync';
import { CountdownEvent, formatDate } from '../main/ets/model/CountdownEvent';
import { mock, resetMock, fakeContext, brokenContext } from './helpers/Harness';

function today0(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function isoShift(days: number): string {
  const d = new Date(today0().getTime() + days * 86400000);
  return formatDate(new Date(d.getFullYear(), d.getMonth(), d.getDate()));
}

function ev(name: string, days: number, category: string): CountdownEvent {
  const e = new CountdownEvent();
  e.id = 'id-' + name;
  e.name = name;
  e.targetDate = isoShift(days);
  e.category = category;
  return e;
}

function seedForms(ids: string[], dims: Record<string, number>): void {
  let store = mock.prefs.get('daysmatter_store');
  if (store === undefined) {
    store = new Map<string, Object>();
    mock.prefs.set('daysmatter_store', store);
  }
  store.set('form_ids', JSON.stringify(ids));
  store.set('form_dims', JSON.stringify(dims));
}

export default function cardSyncTest() {
  describe('CardSync.buildPayload', () => {
    beforeEach(() => {
      resetMock();
    });

    it('没有事件时给出占位内容', 0, () => {
      const payload = CardSync.buildPayload([]);
      expect(payload['eventName']).assertEqual('暂无事件');
      expect(payload['daysText']).assertEqual('--');
      expect(payload['count']).assertEqual('0');
      expect(payload['itemsJson']).assertEqual('[]');
      expect(payload['wide']).assertEqual('0');
    });

    it('置顶事件排在首位', 0, () => {
      const far = ev('远行', 30, 'other');
      const pinned = ev('纪念日', 10, 'anniversary');
      pinned.pinned = true;
      const payload = CardSync.buildPayload([far, pinned]);
      expect(payload['eventName']).assertEqual('纪念日');
      expect(payload['count']).assertEqual('2');
    });

    it('按剩余天数升序取最近的一条', 0, () => {
      const payload = CardSync.buildPayload([ev('远行', 30, 'other'), ev('考试', 2, 'work')]);
      expect(payload['eventName']).assertEqual('考试');
      expect(payload['daysText']).assertEqual('2 天');
    });

    it('今天/已过的天数文案', 0, () => {
      expect(CardSync.buildPayload([ev('今天', 0, 'other')])['daysText']).assertEqual('今天');
      expect(CardSync.buildPayload([ev('过去', -5, 'other')])['daysText']).assertEqual('已过 5 天');
    });

    it('每年重复事件显示月-日', 0, () => {
      const e = ev('生日', 5, 'birthday');
      e.repeatYearly = true;
      const payload = CardSync.buildPayload([e]);
      expect(payload['dateText']).assertEqual(`每年 ${e.targetDate.substring(5)}`);
    });

    it('一次性事件显示完整日期', 0, () => {
      const e = ev('考试', 5, 'work');
      expect(CardSync.buildPayload([e])['dateText']).assertEqual(e.targetDate);
    });

    it('2×4 卡片最多三行', 0, () => {
      const payload = CardSync.buildPayload([
        ev('a', 1, 'other'), ev('b', 2, 'other'), ev('c', 3, 'other'), ev('d', 4, 'other')
      ]);
      const rows = JSON.parse(payload['itemsJson']) as CardRow[];
      expect(rows.length).assertEqual(3);
      expect(rows[0].name).assertEqual('a');
      expect(rows[0].emoji.length > 0).assertTrue();
    });

    it('不修改传入数组', 0, () => {
      const list = [ev('a', 10, 'other'), ev('b', 1, 'other')];
      CardSync.buildPayload(list);
      expect(list[0].name).assertEqual('a');
    });
  });

  describe('CardSync.updateAllCards', () => {
    beforeEach(() => {
      resetMock();
    });

    it('没有已添加卡片时直接返回', 0, async () => {
      await CardSync.updateAllCards(fakeContext(), [ev('a', 1, 'other')]);
      expect(mock.forms.updates.length).assertEqual(0);
    });

    it('按卡片尺寸推送 wide 标记', 0, async () => {
      seedForms(['f1', 'f2'], { 'f1': 3, 'f2': 2 });
      await CardSync.updateAllCards(fakeContext(), [ev('a', 1, 'other')]);
      expect(mock.forms.updates.length).assertEqual(2);
      expect(mock.forms.updates[0].data['wide']).assertEqual('1');
      expect(mock.forms.updates[1].data['wide']).assertEqual('0');
    });

    it('尺寸缺失时按窄卡处理', 0, async () => {
      seedForms(['f3'], {});
      await CardSync.updateAllCards(fakeContext(), [ev('a', 1, 'other')]);
      expect(mock.forms.updates[0].data['wide']).assertEqual('0');
    });

    it('单张卡片推送失败不影响其他卡片', 0, async () => {
      seedForms(['f1', 'f2'], { 'f1': 2, 'f2': 2 });
      mock.forms.throwFor = ['f1'];
      await CardSync.updateAllCards(fakeContext(), [ev('a', 1, 'other')]);
      expect(mock.forms.updates.length).assertEqual(1);
      expect(mock.forms.updates[0].formId).assertEqual('f2');
    });

    it('上下文不可用时静默失败', 0, async () => {
      await CardSync.updateAllCards(brokenContext(), [ev('a', 1, 'other')]);
      expect(true).assertTrue();
    });
  });
}
