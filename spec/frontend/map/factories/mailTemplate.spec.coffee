_ = require 'lodash'

describe 'mailTemplate', ->
  beforeEach ->
    console.log "#### mailTemplate, beforeEach"
    angular.mock.module 'rmapsMapApp'

    inject (rmapsMailTemplate) =>
      @rmapsMailTemplate = rmapsMailTemplate
      @basicLetter = new rmapsMailTemplate("basicLetter")

  it 'rmapsMailTemplate should be ok', ->
    @rmapsMailTemplate.should.be.ok

  it 'basicLetter should be ok', ->
    @basicLetter.should.be.ok


    #expect(obj.field.getTransformString()).to.equal obj.transform for obj in rules
