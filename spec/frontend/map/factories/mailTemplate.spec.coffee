describe 'mailTemplate factory', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')
  
    inject (rmapsMailTemplate) =>
      # $provide.value 'rmapsprincipal',
      #   getIdentity: () ->
      #     user:
      #       id: 1
      @rmapsMailTemplate = rmapsMailTemplate


  describe 'templateObj', ->
    it "tests valid basicLetter", ->
      templateType = 'basicLetter'
      obj = new @rmapsMailTemplate(templateType)
      obj.should.be.ok
      expect(obj.type).to.eql templateType
    # it 'tests appropriate modal functionality ()'
