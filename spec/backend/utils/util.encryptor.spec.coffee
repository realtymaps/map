basePath = require '../basePath'
Encryptor = require "#{basePath}/utils/util.encryptor"


# tests below come from the official NIST definitions for AES-256-CTR; see page 57 of
# http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf

describe 'utils/encryptor'.ns().ns('Backend'), () ->

  describe 'correct AES-256-CTR (default) encryption/decryption', () ->
    cipherKey = '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4'
    initVector = 'f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff'
    encryptor = new Encryptor
      cipherKey: cipherKey
      payloadEncoding: 'hex'
      textEncoding: 'hex'
    plaintext = [
      '6bc1bee22e409f96e93d7e117393172a'
      'ae2d8a571e03ac9c9eb76fac45af8e51'
      '30c81c46a35ce411e5fbc1191a0a52ef'
      'f69f2445df4f9b17ad2b417be66c3710'
    ].join('')
    payload = initVector + '$$'+ [
      '601ec313775789a5b7a7f504bbf3d228'
      'f443e3ca4d62b59aca84e990cacaf5c5'
      '2b0930daa23de94ce87017ba2d84988d'
      'dfc9c58db67aada613c2dd08457941a6'
    ].join('') + '$'
  
    it 'should encrypt input as per NIST documentation', () ->
      encryptor.encrypt(plaintext, null, initVector)
      .should.equal(payload)
    
    it 'should decrypt back to input as per NIST documentation', () ->
      encryptor.decrypt(payload)
      .should.equal(plaintext)

  # TODO: test more constructor options, such as random IV, no IV, HMAC tests, alternate encodings, etc
