describe 'rmapsEditTemplateCtrl', ->

  beforeEach ->
    angular.mock.module('rmapsMapFactoryApp')
  
    inject ($controller, $rootScope, $document, rmapsMailTemplateService) =>
      @document = $document[0]
      @$controller = $controller
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()
      @rmapsMailTemplateService = rmapsMailTemplate

  describe 'controller behavior', ->
    it 'vetting controller logic', ->      
      controller = @$controller 'rmapsEditTemplateCtrl', { $scope: @scope }
      expect(@scope.templObj).to.be.ok

