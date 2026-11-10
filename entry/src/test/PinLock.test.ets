import { describe, it, expect } from '@ohos/hypium';
import {
  PIN_LENGTH,
  MAX_PIN_ATTEMPTS,
  PIN_LOCK_SECONDS,
  sha256Hex,
  normalizePin,
  isValidPin,
  randomSalt,
  hashPin,
  verifyPin,
  remainingAttempts,
  lockoutUntil,
  lockSecondsLeft
} from '../main/ets/common/PinLock';

const HEX64 = /^[0-9a-f]{64}$/;

function repeat(ch: string, times: number): string {
  let out = '';
  for (let i = 0; i < times; i++) {
    out += ch;
  }
  return out;
}

export default function pinLockTest() {
  describe('PinLock.SHA256 摘要', () => {
    it('标准测试向量：空串', 0, () => {
      expect(sha256Hex(''))
        .assertEqual('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });

    it('标准测试向量：abc', 0, () => {
      expect(sha256Hex('abc'))
        .assertEqual('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    it('标准测试向量：英文句子', 0, () => {
      expect(sha256Hex('The quick brown fox jumps over the lazy dog'))
        .assertEqual('d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592');
    });

    it('UTF-8 多字节字符按字节计算', 0, () => {
      expect(sha256Hex('中文测试'))
        .assertEqual('e350545d18735c5dd2dec50dcb971f3eb4cdda24b95a79bdb6b553f6a01ceb87');
    });

    it('跨多个 64 字节分组时结果正确', 0, () => {
      expect(sha256Hex(repeat('a', 1000)))
        .assertEqual('41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3');
    });

    it('两字节 UTF-8 字符（如 é）编码正确', 0, () => {
      expect(sha256Hex(String.fromCharCode(0xe9)))
        .assertEqual('4a99557e4033c3539de2eb65472017cad5f9557f7a0625a09f1c3f6e2ba69c4c');
    });

    it('四字节字符（代理对，如 😀）编码正确', 0, () => {
      const emoji = String.fromCharCode(0xd83d, 0xde00);
      expect(sha256Hex(emoji))
        .assertEqual('f0443a342c5ef54783a111b51ba56c938e474c32324d90c3a60c9c8e3a37e2d9');
    });

    it('混合 ASCII / 两字节 / 四字节 / 三字节时编码正确', 0, () => {
      const mixed = 'a' + String.fromCharCode(0xe9) + String.fromCharCode(0xd83d, 0xde00) + '中';
      expect(sha256Hex(mixed))
        .assertEqual('c1ccab59ab89fd73b0d8a34aab4774eedcc465908d73f13ae8d587db979caf44');
    });

    it('摘要固定为 64 位小写十六进制', 0, () => {
      expect(HEX64.test(sha256Hex('1234'))).assertTrue();
    });
  });

  describe('PinLock.PIN 规范化与校验', () => {
    it('去掉空格与连字符，只留数字', 0, () => {
      expect(normalizePin(' 12 34 ')).assertEqual('1234');
      expect(normalizePin('1-2-3-4')).assertEqual('1234');
      expect(normalizePin('ab12cd34')).assertEqual('1234');
    });

    it('超长输入截断到 4 位', 0, () => {
      expect(normalizePin('123456')).assertEqual('1234');
      expect(normalizePin('123456').length).assertEqual(PIN_LENGTH);
    });

    it('纯字母/空串规范化为空', 0, () => {
      expect(normalizePin('abcd')).assertEqual('');
      expect(normalizePin('')).assertEqual('');
    });

    it('只接受恰好 4 位数字', 0, () => {
      expect(isValidPin('1234')).assertTrue();
      expect(isValidPin('0000')).assertTrue();
      expect(isValidPin('123')).assertFalse();
      expect(isValidPin('12345')).assertFalse();
      expect(isValidPin('12a4')).assertFalse();
      expect(isValidPin('')).assertFalse();
    });
  });

  describe('PinLock.加盐摘要', () => {
    it('随机盐为 16 位十六进制且每次不同', 0, () => {
      const a = randomSalt();
      const b = randomSalt();
      expect(a.length).assertEqual(16);
      expect(/^[0-9a-f]{16}$/.test(a)).assertTrue();
      expect(a === b).assertFalse();
    });

    it('同一 PIN + 同一盐得到相同摘要', 0, () => {
      expect(hashPin('1234', '0123456789abcdef'))
        .assertEqual('c9f29cbedcc0104cfa8a7755f2bebdb620997d0cb56ddd228f30318c001f4b4a');
    });

    it('盐不同则摘要不同（避免彩虹表）', 0, () => {
      const h1 = hashPin('1234', '0123456789abcdef');
      const h2 = hashPin('1234', 'fedcba9876543210');
      expect(h1 === h2).assertFalse();
    });

    it('PIN 不同则摘要不同', 0, () => {
      const salt = '0123456789abcdef';
      expect(hashPin('1234', salt) === hashPin('1235', salt)).assertFalse();
    });

    it('摘要中不含明文 PIN', 0, () => {
      expect(hashPin('1234', '0123456789abcdef').includes('1234')).assertFalse();
    });

    it('校验：正确 PIN 通过，错误 PIN 失败', 0, () => {
      const salt = randomSalt();
      const hash = hashPin('0420', salt);
      expect(verifyPin('0420', salt, hash)).assertTrue();
      expect(verifyPin('0421', salt, hash)).assertFalse();
    });

    it('未设置摘要时校验一律失败', 0, () => {
      expect(verifyPin('1234', '0123456789abcdef', '')).assertFalse();
    });
  });

  describe('PinLock.失败次数与锁定策略', () => {
    it('剩余次数随失败递增归零', 0, () => {
      expect(remainingAttempts(0)).assertEqual(MAX_PIN_ATTEMPTS);
      expect(remainingAttempts(MAX_PIN_ATTEMPTS - 1)).assertEqual(1);
      expect(remainingAttempts(MAX_PIN_ATTEMPTS)).assertEqual(0);
      expect(remainingAttempts(MAX_PIN_ATTEMPTS + 3)).assertEqual(0);
    });

    it('锁定截止时间 = 当前 + 30 秒', 0, () => {
      expect(lockoutUntil(1000)).assertEqual(1000 + PIN_LOCK_SECONDS * 1000);
    });

    it('未到截止时间为 0', 0, () => {
      expect(lockSecondsLeft(1000, 1000)).assertEqual(0);
      expect(lockSecondsLeft(2000, 1000)).assertEqual(0);
    });

    it('剩余秒数向上取整', 0, () => {
      expect(lockSecondsLeft(0, 1000)).assertEqual(1);
      expect(lockSecondsLeft(0, 1500)).assertEqual(2);
      expect(lockSecondsLeft(0, 30000)).assertEqual(PIN_LOCK_SECONDS);
    });
  });
}
