/**
 * 隐私锁 PIN 的安全处理（纯本地、纯函数，便于单元测试）
 *
 * 设计要点：
 * - 绝不保存明文：只保存 16 位随机盐 + SHA-256(盐 + ':' + PIN) 的十六进制摘要，
 *   即使有人导出了应用 Preferences 文件，也看不到 PIN 本身；
 * - 提供输入规范化、格式校验、剩余次数、锁定倒计时等纯逻辑；
 * - 自带 SHA-256 实现，不依赖系统加密框架，行为在设备与测试环境完全一致。
 */

export const PIN_LENGTH: number = 4;
/** 连续错误达到该次数后短暂锁定，避免被快速穷举 */
export const MAX_PIN_ATTEMPTS: number = 5;
/** 锁定时长（秒） */
export const PIN_LOCK_SECONDS: number = 30;

const SALT_LENGTH: number = 16;

/** SHA-256 轮常量 */
const K: number[] = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

function rotr(x: number, n: number): number {
  return ((x >>> n) | (x << (32 - n))) >>> 0;
}

/** 字符串按 UTF-8 拆成字节数组（PIN 只有数字，此处仍做完整实现以便复用） */
function utf8Bytes(text: string): number[] {
  const bytes: number[] = [];
  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i);
    if (code < 0x80) {
      bytes.push(code);
    } else if (code < 0x800) {
      bytes.push(0xc0 | (code >> 6));
      bytes.push(0x80 | (code & 0x3f));
    } else if (code < 0xd800 || code >= 0xe000) {
      bytes.push(0xe0 | (code >> 12));
      bytes.push(0x80 | ((code >> 6) & 0x3f));
      bytes.push(0x80 | (code & 0x3f));
    } else {
      // 代理对：合并为一个补充平面字符
      i++;
      const low = text.charCodeAt(i);
      const cp = 0x10000 + (((code & 0x3ff) << 10) | (low & 0x3ff));
      bytes.push(0xf0 | (cp >> 18));
      bytes.push(0x80 | ((cp >> 12) & 0x3f));
      bytes.push(0x80 | ((cp >> 6) & 0x3f));
      bytes.push(0x80 | (cp & 0x3f));
    }
  }
  return bytes;
}

function hexWord(value: number): string {
  return (value >>> 0).toString(16).padStart(8, '0');
}

/**
 * 计算 SHA-256 摘要（小写十六进制，64 字符）
 */
export function sha256Hex(text: string): string {
  const msg: number[] = utf8Bytes(text);
  const bitLen = msg.length * 8;

  msg.push(0x80);
  while (msg.length % 64 !== 56) {
    msg.push(0);
  }
  const high = Math.floor(bitLen / 4294967296);
  const low = bitLen % 4294967296;
  msg.push((high >>> 24) & 0xff);
  msg.push((high >>> 16) & 0xff);
  msg.push((high >>> 8) & 0xff);
  msg.push(high & 0xff);
  msg.push((low >>> 24) & 0xff);
  msg.push((low >>> 16) & 0xff);
  msg.push((low >>> 8) & 0xff);
  msg.push(low & 0xff);

  const h: number[] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ];

  const w: number[] = [];
  for (let i = 0; i < 64; i++) {
    w.push(0);
  }

  for (let chunk = 0; chunk < msg.length; chunk += 64) {
    for (let i = 0; i < 16; i++) {
      const base = chunk + i * 4;
      w[i] = (((msg[base] << 24) | (msg[base + 1] << 16) | (msg[base + 2] << 8) | msg[base + 3]) >>> 0);
    }
    for (let i = 16; i < 64; i++) {
      const x = w[i - 15];
      const y = w[i - 2];
      const s0 = (rotr(x, 7) ^ rotr(x, 18) ^ (x >>> 3)) >>> 0;
      const s1 = (rotr(y, 17) ^ rotr(y, 19) ^ (y >>> 10)) >>> 0;
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) >>> 0;
    }

    let a = h[0];
    let b = h[1];
    let c = h[2];
    let d = h[3];
    let e = h[4];
    let f = h[5];
    let g = h[6];
    let hh = h[7];

    for (let i = 0; i < 64; i++) {
      const s1 = (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) >>> 0;
      const ch = ((e & f) ^ (~e & g)) >>> 0;
      const temp1 = (hh + s1 + ch + K[i] + w[i]) >>> 0;
      const s0 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) >>> 0;
      const maj = ((a & b) ^ (a & c) ^ (b & c)) >>> 0;
      const temp2 = (s0 + maj) >>> 0;

      hh = g;
      g = f;
      f = e;
      e = (d + temp1) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) >>> 0;
    }

    h[0] = (h[0] + a) >>> 0;
    h[1] = (h[1] + b) >>> 0;
    h[2] = (h[2] + c) >>> 0;
    h[3] = (h[3] + d) >>> 0;
    h[4] = (h[4] + e) >>> 0;
    h[5] = (h[5] + f) >>> 0;
    h[6] = (h[6] + g) >>> 0;
    h[7] = (h[7] + hh) >>> 0;
  }

  return hexWord(h[0]) + hexWord(h[1]) + hexWord(h[2]) + hexWord(h[3])
    + hexWord(h[4]) + hexWord(h[5]) + hexWord(h[6]) + hexWord(h[7]);
}

/**
 * 只保留数字，并截断到 4 位（输入法可能带入空格或连字符）
 */
export function normalizePin(raw: string): string {
  let digits = '';
  for (let i = 0; i < raw.length; i++) {
    const ch = raw.charAt(i);
    if (ch >= '0' && ch <= '9') {
      digits += ch;
    }
  }
  return digits.substring(0, PIN_LENGTH);
}

/**
 * 是否为合法 PIN（恰好 4 位数字）
 */
export function isValidPin(pin: string): boolean {
  if (pin.length !== PIN_LENGTH) {
    return false;
  }
  for (let i = 0; i < pin.length; i++) {
    const ch = pin.charAt(i);
    if (ch < '0' || ch > '9') {
      return false;
    }
  }
  return true;
}

/**
 * 生成随机盐（16 位十六进制）
 */
export function randomSalt(): string {
  const hex = '0123456789abcdef';
  let salt = '';
  for (let i = 0; i < SALT_LENGTH; i++) {
    salt += hex.charAt(Math.floor(Math.random() * hex.length));
  }
  return salt;
}

/**
 * 加盐摘要：SHA-256(盐 + ':' + PIN)
 */
export function hashPin(pin: string, salt: string): string {
  return sha256Hex(`${salt}:${pin}`);
}

/**
 * 校验 PIN 是否与已保存的摘要匹配
 */
export function verifyPin(pin: string, salt: string, storedHash: string): boolean {
  if (storedHash.length === 0) {
    return false;
  }
  return hashPin(pin, salt) === storedHash;
}

/**
 * 剩余可尝试次数
 */
export function remainingAttempts(fails: number): number {
  const left = MAX_PIN_ATTEMPTS - fails;
  return left > 0 ? left : 0;
}

/**
 * 由当前时间推出锁定截止时间戳
 */
export function lockoutUntil(now: number): number {
  return now + PIN_LOCK_SECONDS * 1000;
}

/**
 * 距离解锁还剩几秒（0 表示未锁定）
 */
export function lockSecondsLeft(now: number, until: number): number {
  if (until <= now) {
    return 0;
  }
  return Math.ceil((until - now) / 1000);
}

/**
 * PIN 校验结果
 */
export interface PinVerifyResult {
  /** 是否验证通过 */
  ok: boolean;
  /** 是否为旧版明文 PIN 验证通过（调用方应迁移为摘要存储） */
  legacy: boolean;
}
