

describe 'mailTemplateType service', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')
  
    inject (rmapsMailTemplateTypeService) =>
      @svc = rmapsMailTemplateTypeService
      @type = 'basicLetter'

  describe 'service members', ->
    it "passes sanity check", ->
      @svc.should.be.ok
      @svc.getDefaultHtml(@type).should.be.ok
      @svc.getDefaultFinalStyle(@type).should.be.ok

    it "should have correct types", ->
      expect(@svc.getTypeNames()).to.include.members ['basicLetter']

    it "should have correct categories", ->
      expect(@svc.getCategories()).to.eql [
        ['all', 'All Templates']
        ['letter', 'Letters']
        ['postcard', 'Postcards']
        ['favorite', 'Favorites']
        ['custom', 'Custom']
      ]
