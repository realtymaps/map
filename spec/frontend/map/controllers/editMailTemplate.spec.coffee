describe 'rmapsEditTemplateCtrl', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject ($controller, $rootScope, $document, rmapsMailTemplateService) =>
      @document = $document[0]
      @$controller = $controller
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()
      @rmapsMailTemplateService = rmapsMailTemplateService

  describe 'controller behavior', ->
    it 'vetting controller logic', ->
      controller = @$controller 'rmapsEditTemplateCtrl', { $scope: @scope }
      expect(@scope.templObj).to.be.ok

