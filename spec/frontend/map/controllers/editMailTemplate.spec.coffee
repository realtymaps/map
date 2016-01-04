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

  describe 'controller behavior', ->
    # lumping multiple tests on controller here so that we aren't re-evaluating controller over and over
    xit 'vetting controller logic', ->
      templateType = 'basicLetter'
      @scope.templateType = templateType
      
      controller = @$controller 'rmapsEditTemplateCtrl', { $scope: @scope }
      expect(@scope.templateObj).to.be.ok

