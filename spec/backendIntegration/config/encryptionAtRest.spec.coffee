require("chai").should()
{basePath} = require '../globalSetup'


describe 'ENCRYPTION_AT_REST', () ->

  encryptor = require "#{basePath}/config/encryptor"

  it 'should decrypt to a known string', () ->
    encryptor.decrypt('1+1GDvOrzpSe/p6lBlzkOQ==$$TdAmWuLMgXVY8h9aB/Y9QnxjeIA1BiGyTTY3Pjx5$')
    .should.equal 'you are using the correct key!'
