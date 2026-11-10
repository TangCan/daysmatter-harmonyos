/** @kit.ArkTS 桩：util.TextDecoder */
const util = {
  TextDecoder: {
    create(encoding) {
      return {
        decodeToString(input) {
          return Buffer.from(input).toString('utf8');
        }
      };
    }
  }
};

module.exports = { util };
