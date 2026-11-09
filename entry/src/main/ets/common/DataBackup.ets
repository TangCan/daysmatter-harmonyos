import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { CountdownEvent } from '../model/CountdownEvent';
import { EventStore } from './EventStore';

interface BackupPayload {
  app: string;
  version: number;
  exportedAt: string;
  events: CountdownEvent[];
}

/**
 * 数据备份：JSON 导出/导入
 * 全部通过系统文件选择器（DocumentViewPicker）完成，无需任何存储权限；
 * 数据不离开用户自己选择的文件。
 */
export class DataBackup {
  /**
   * 导出全部事件到用户指定的 JSON 文件，返回结果描述
   */
  static async exportData(context: common.Context, events: CountdownEvent[]): Promise<string> {
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [`daysmatter-backup-${new Date().toISOString().substring(0, 10)}.json`];
    options.fileSuffixChoices = ['.json'];
    const docPicker = new picker.DocumentViewPicker();
    const uris = await docPicker.save(options);
    if (uris.length === 0) {
      return '已取消';
    }
    const payload = JSON.stringify({
      app: 'daysmatter',
      version: 1,
      exportedAt: new Date().toISOString(),
      events: events
    });
    const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, payload);
    fileIo.closeSync(file.fd);
    return `已导出 ${events.length} 个日子`;
  }

  /**
   * 从用户选择的 JSON 文件导入事件（合并：按 id 去重，同 id 覆盖）
   * 返回结果描述；导入成功后已写回本地存储
   */
  static async importData(context: common.Context): Promise<string> {
    const options = new picker.DocumentSelectOptions();
    options.fileSuffixFilters = ['.json'];
    options.maxSelectNumber = 1;
    const docPicker = new picker.DocumentViewPicker();
    const uris = await docPicker.select(options);
    if (uris.length === 0) {
      return '已取消';
    }
    const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
    const stat = fileIo.statSync(file.fd);
    const buf = new ArrayBuffer(stat.size);
    fileIo.readSync(file.fd, buf);
    fileIo.closeSync(file.fd);
    const decoder = util.TextDecoder.create('utf-8');
    const text = decoder.decodeToString(new Uint8Array(buf));
    const parsed = JSON.parse(text) as BackupPayload;
    if (parsed.app !== 'daysmatter' || !Array.isArray(parsed.events)) {
      return '文件格式不正确，请选择本应用导出的 JSON';
    }
    const incoming = parsed.events.map((o: CountdownEvent) => CountdownEvent.fromJson(o));
    const current = await EventStore.load(context);
    const merged = new Map<string, CountdownEvent>();
    for (const e of current) {
      merged.set(e.id, e);
    }
    let added = 0;
    let updated = 0;
    for (const e of incoming) {
      if (merged.has(e.id)) {
        updated++;
      } else {
        added++;
      }
      merged.set(e.id, e);
    }
    const result = Array.from(merged.values());
    await EventStore.save(context, result);
    return `导入完成：新增 ${added} 个，更新 ${updated} 个，共 ${result.length} 个`;
  }
}
