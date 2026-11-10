import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { DataBackup } from '../main/ets/common/DataBackup';
import { EventStore } from '../main/ets/common/EventStore';
import { CountdownEvent } from '../main/ets/model/CountdownEvent';
import { mock, resetMock, fakeContext } from './helpers/Harness';

const EXPORT_URI = 'file://docs/backup.json';
const IMPORT_URI = 'file://docs/incoming.json';

function sampleEvent(id: string, name: string): CountdownEvent {
  const e = new CountdownEvent();
  e.id = id;
  e.name = name;
  e.targetDate = '2030-05-20';
  e.category = 'birthday';
  return e;
}

function writeMockFile(uri: string, text: string): void {
  mock.fs.files.set(uri, Buffer.from(text, 'utf8'));
}

function readMockFile(uri: string): string {
  const content = mock.fs.files.get(uri) as Buffer;
  return content.toString('utf8');
}

export default function dataBackupTest() {
  describe('DataBackup.exportData', () => {
    beforeEach(() => {
      resetMock();
    });

    it('导出后文件内容包含全部事件', 0, async () => {
      mock.picker.saveUris = [EXPORT_URI];
      const msg = await DataBackup.exportData(fakeContext(), [sampleEvent('a', '生日'), sampleEvent('b', '纪念日')]);
      expect(msg).assertEqual('已导出 2 个日子');
      const payload = JSON.parse(readMockFile(EXPORT_URI));
      expect(payload.app).assertEqual('daysmatter');
      expect(payload.version).assertEqual(1);
      expect(payload.events.length).assertEqual(2);
      expect(payload.events[0].name).assertEqual('生日');
    });

    it('用户取消保存时返回已取消', 0, async () => {
      mock.picker.saveUris = [];
      const msg = await DataBackup.exportData(fakeContext(), [sampleEvent('a', '生日')]);
      expect(msg).assertEqual('已取消');
    });

    it('选择器异常向上抛出（由页面兜底提示）', 0, async () => {
      mock.picker.throwOnSave = true;
      let thrown = false;
      try {
        await DataBackup.exportData(fakeContext(), []);
      } catch (err) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });

  describe('DataBackup.importData', () => {
    beforeEach(() => {
      resetMock();
    });

    it('导入新事件并统计新增数量', 0, async () => {
      mock.picker.selectUris = [IMPORT_URI];
      writeMockFile(IMPORT_URI, JSON.stringify({
        app: 'daysmatter',
        version: 1,
        exportedAt: '2026-01-01T00:00:00.000Z',
        events: [sampleEvent('x1', '新事件'), sampleEvent('x2', '另一个')]
      }));
      const msg = await DataBackup.importData(fakeContext());
      expect(msg).assertEqual('导入完成：新增 2 个，更新 0 个，共 2 个');
      const stored = await EventStore.load(fakeContext());
      expect(stored.length).assertEqual(2);
      expect(stored[0].name).assertEqual('新事件');
    });

    it('同 id 视为更新而非新增', 0, async () => {
      await EventStore.save(fakeContext(), [sampleEvent('x1', '旧名字')]);
      mock.picker.selectUris = [IMPORT_URI];
      writeMockFile(IMPORT_URI, JSON.stringify({
        app: 'daysmatter',
        version: 1,
        exportedAt: '2026-01-01T00:00:00.000Z',
        events: [sampleEvent('x1', '新名字'), sampleEvent('x2', '新增的')]
      }));
      const msg = await DataBackup.importData(fakeContext());
      expect(msg).assertEqual('导入完成：新增 1 个，更新 1 个，共 2 个');
      const stored = await EventStore.load(fakeContext());
      const updated = stored.find((e: CountdownEvent) => e.id === 'x1') as CountdownEvent;
      expect(updated.name).assertEqual('新名字');
    });

    it('用户取消选择时返回已取消', 0, async () => {
      mock.picker.selectUris = [];
      const msg = await DataBackup.importData(fakeContext());
      expect(msg).assertEqual('已取消');
    });

    it('不是本应用导出的文件时给出提示', 0, async () => {
      mock.picker.selectUris = [IMPORT_URI];
      writeMockFile(IMPORT_URI, JSON.stringify({ app: 'other-app', events: [] }));
      const msg = await DataBackup.importData(fakeContext());
      expect(msg).assertContain('文件格式不正确');
    });

    it('events 不是数组时给出提示', 0, async () => {
      mock.picker.selectUris = [IMPORT_URI];
      writeMockFile(IMPORT_URI, JSON.stringify({ app: 'daysmatter', events: 'oops' }));
      const msg = await DataBackup.importData(fakeContext());
      expect(msg).assertContain('文件格式不正确');
    });

    it('文件内容不是合法 JSON 时抛错', 0, async () => {
      mock.picker.selectUris = [IMPORT_URI];
      writeMockFile(IMPORT_URI, 'not-a-json');
      let thrown = false;
      try {
        await DataBackup.importData(fakeContext());
      } catch (err) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });
}
