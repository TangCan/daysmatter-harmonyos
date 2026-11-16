import { describe, it, expect } from '@ohos/hypium';
import {
  parseCustomCategories,
  mergeCategories,
  optionOf,
  newCustomCategory,
  CUSTOM_CATEGORY_LIMIT,
  CUSTOM_CATEGORY_NAME_MAX,
  CategoryOption
} from '../main/ets/model/CountdownEvent';

export default function customCategoryTest() {
  describe('CustomCategory.parse', () => {
    it('解析合法 JSON 数组', 0, () => {
      const list = parseCustomCategories('[{"key":"c_1","label":"学习","emoji":"🏷️"}]');
      expect(list.length).assertEqual(1);
      expect(list[0].key).assertEqual('c_1');
      expect(list[0].label).assertEqual('学习');
    });

    it('非法 JSON 返回空数组', 0, () => {
      expect(parseCustomCategories('not-json').length).assertEqual(0);
      expect(parseCustomCategories('').length).assertEqual(0);
      expect(parseCustomCategories('"text"').length).assertEqual(0);
    });

    it('非 c_ 前缀 key 被过滤', 0, () => {
      const list = parseCustomCategories('[{"key":"birthday","label":"假生日"},{"key":"c_2","label":"真分类"}]');
      expect(list.length).assertEqual(1);
      expect(list[0].key).assertEqual('c_2');
    });

    it('空名称与超长名称被过滤', 0, () => {
      const list = parseCustomCategories('[{"key":"c_3","label":""},{"key":"c_4","label":"这个名称实在是太长了"},{"key":"c_5","label":"OK"}]');
      expect(list.length).assertEqual(1);
      expect(list[0].key).assertEqual('c_5');
    });

    it('重复 key 去重且最多保留上限个', 0, () => {
      const raw = '[{"key":"c_1","label":"A"},{"key":"c_1","label":"A2"},{"key":"c_2","label":"B"},{"key":"c_3","label":"C"},{"key":"c_4","label":"D"},{"key":"c_5","label":"E"},{"key":"c_6","label":"F"},{"key":"c_7","label":"G"}]';
      const list = parseCustomCategories(raw);
      expect(list.length).assertEqual(CUSTOM_CATEGORY_LIMIT);
      expect(list[0].label).assertEqual('A');
    });
  });

  describe('CustomCategory.merge', () => {
    it('预设 5 个 + 自建若干', 0, () => {
      const custom: CategoryOption[] = parseCustomCategories('[{"key":"c_9","label":"健身"}]');
      const all = mergeCategories(custom);
      expect(all.length).assertEqual(6);
      expect(all[0].key).assertEqual('birthday');
      expect(all[5].label).assertEqual('健身');
    });

    it('optionOf 命中预设与自建，未知回落其他', 0, () => {
      const custom: CategoryOption[] = parseCustomCategories('[{"key":"c_9","label":"健身"}]');
      expect(optionOf('work', custom).label).assertEqual('工作');
      expect(optionOf('c_9', custom).label).assertEqual('健身');
      expect(optionOf('nope', custom).key).assertEqual('other');
    });
  });

  describe('CustomCategory.new', () => {
    it('正常创建 c_ 前缀 key', 0, () => {
      const opt = newCustomCategory(' 阅读 ', []);
      expect(opt !== undefined).assertTrue();
      if (opt !== undefined) {
        expect(opt.key.startsWith('c_')).assertTrue();
        expect(opt.label).assertEqual('阅读');
      }
    });

    it('空名/超长名返回 undefined', 0, () => {
      expect(newCustomCategory('   ', []) === undefined).assertTrue();
      expect(newCustomCategory('名字太长肯定不行', []) === undefined).assertTrue();
    });

    it('与预设或已有分类重名返回 undefined', 0, () => {
      expect(newCustomCategory('工作', []) === undefined).assertTrue();
      const existing: CategoryOption[] = parseCustomCategories('[{"key":"c_1","label":"学习"}]');
      expect(newCustomCategory('学习', existing) === undefined).assertTrue();
    });

    it('自建数量达到上限后拒绝创建', 0, () => {
      const raw = '[{"key":"c_1","label":"一"},{"key":"c_2","label":"二"},{"key":"c_3","label":"三"},{"key":"c_4","label":"四"},{"key":"c_5","label":"五"},{"key":"c_6","label":"六"}]';
      const existing: CategoryOption[] = parseCustomCategories(raw);
      expect(existing.length).assertEqual(CUSTOM_CATEGORY_LIMIT);
      expect(newCustomCategory('七', existing) === undefined).assertTrue();
    });
  });
}
