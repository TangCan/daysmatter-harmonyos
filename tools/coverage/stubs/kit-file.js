/** @kit.CoreFileKit 桩：picker(文件选择器) + fileIo(内存文件系统) */
const { state } = require('../state');

class DocumentSaveOptions {
  constructor() {
    this.newFileNames = [];
    this.fileSuffixChoices = [];
  }
}

class DocumentSelectOptions {
  constructor() {
    this.maxSelectNumber = 1;
    this.fileSuffixFilters = [];
  }
}

class DocumentViewPicker {
  async save(options) {
    state.picker.saveOptions = options;
    if (state.picker.throwOnSave) {
      throw new Error('mock save failure');
    }
    return state.picker.saveUris;
  }

  async select(options) {
    state.picker.selectOptions = options;
    if (state.picker.throwOnSelect) {
      throw new Error('mock select failure');
    }
    return state.picker.selectUris;
  }
}

const picker = { DocumentSaveOptions, DocumentSelectOptions, DocumentViewPicker };

const OpenMode = {
  READ_ONLY: 0,
  WRITE_ONLY: 1,
  READ_WRITE: 2,
  CREATE: 64,
  TRUNC: 512
};

function openSync(filePath, mode) {
  const fd = state.fs.nextFd++;
  state.fs.fds.set(fd, filePath);
  if (!state.fs.files.has(filePath)) {
    state.fs.files.set(filePath, Buffer.alloc(0));
  }
  return { fd, path: filePath };
}

function writeSync(fd, data) {
  const filePath = state.fs.fds.get(fd);
  const content = typeof data === 'string' ? Buffer.from(data, 'utf8') : Buffer.from(data);
  state.fs.files.set(filePath, content);
  return content.length;
}

function readSync(fd, buffer) {
  const filePath = state.fs.fds.get(fd);
  const content = state.fs.files.get(filePath) || Buffer.alloc(0);
  const view = new Uint8Array(buffer);
  view.set(content.subarray(0, view.length));
  return Math.min(content.length, view.length);
}

function statSync(fd) {
  const filePath = state.fs.fds.get(fd);
  const content = state.fs.files.get(filePath) || Buffer.alloc(0);
  return { size: content.length };
}

function closeSync(fd) {
  return;
}

function unlinkSync(filePath) {
  if (!state.fs.files.has(filePath)) {
    throw new Error('no such file');
  }
  state.fs.files.delete(filePath);
}

function copyFile(srcFd, destFd) {
  const src = state.fs.fds.get(srcFd);
  const dest = state.fs.fds.get(destFd);
  const content = state.fs.files.get(src) || Buffer.alloc(0);
  state.fs.files.set(dest, Buffer.from(content));
}

function accessSync() {
  return;
}

const fileIo = { OpenMode, openSync, writeSync, readSync, statSync, closeSync, unlinkSync, copyFile, accessSync };

const fileUri = {
  getUriFromPath(p) {
    return 'file://' + p;
  }
};

module.exports = { picker, fileIo, fileUri };
