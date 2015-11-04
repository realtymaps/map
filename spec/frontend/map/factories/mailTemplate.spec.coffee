_ = require 'lodash'


describe 'rmapsEditTemplateCtrl', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')
  
    inject ($controller, $rootScope, $document, rmapsMailTemplate) =>
      # $provide.value 'rmapsprincipal',
      #   getIdentity: () ->
      #     user:
      #       id: 1
      @document = $document[0]
      @$controller = $controller
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()
      @rmapsMailTemplate = rmapsMailTemplate


  describe 'templateObj', ->
    it "tests valid basicLetter", ->
      templateType = 'basicLetter'
      obj = new @rmapsMailTemplate(templateType)
      obj.should.be.ok
      expect(obj.type).to.eql templateType
    # it 'tests appropriate modal functionality ()'


  describe 'controller behavior', ->
    # lumping multiple tests on controller here so that we aren't re-evaluating controller over and over
    it 'vetting controller logic', ->
      templateType = 'basicLetter'
      @scope.$parent['templateType'] = templateType
      
      controller = @$controller 'rmapsEditTemplateCtrl', { $scope: @scope }
      expect(@scope.templateObj.type).to.eql templateType

      # it 'ensures template class names are set correctly'
      expect(@scope.applyTemplateClass()).to.eql "#{templateType}"
      expect(@scope.applyTemplateClass('-body')).to.eql "#{templateType}-body"

      # it 'vets appropriate changes to data.htmlcontent that occur during $watch (like macro management)'
      # console.log "confirm document:"
      # console.log JSON.stringify(@document)
      # templateStage = @document.getElementsByClassName('template-stage')
      # console.log JSON.stringify(templateStage)
      # console.log templateStage[0]
      # sel = rangy.getSelection()
      # console.log "rangy thing:"
      # console.log sel

      # it 'adds macros appropriately to given text'
      # @backupDocument = _.cloneDeep @document
      # spyCb = sinon.spy @$rootScope, '$emit'

