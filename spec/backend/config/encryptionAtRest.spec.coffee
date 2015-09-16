basePath = require '../basePath'
encryptor = require "#{basePath}/config/encryptor"


describe 'ENCRYPTION_AT_REST', () ->

  if process.env.CIRCLECI
    it "can't run on CircleCI because we don't have the encryption key there", () ->
      #noop
    return
    
  it 'should decrypt to a known string', () ->
    encryptor.decrypt('1+1GDvOrzpSe/p6lBlzkOQ==$$TdAmWuLMgXVY8h9aB/Y9QnxjeIA1BiGyTTY3Pjx5$')
    .should.equal 'you are using the correct key!'
