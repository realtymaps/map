Encryptor = require '../utils/util.encryptor'
config = require '../config/config'

module.exports = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)
