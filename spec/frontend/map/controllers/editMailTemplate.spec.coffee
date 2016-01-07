describe 'rmapsEditTemplateCtrl', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')
  
    inject ($controller, $rootScope, $document, rmapsMailTemplate) =>
      @document = $document[0]
      @$controller = $controller
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()
      @rmapsMailTemplate = rmapsMailTemplate

  describe 'controller behavior', ->
    it 'vetting controller logic', ->      
      controller = @$controller 'rmapsEditTemplateCtrl', { $scope: @scope }
      expect(@scope.templObj).to.be.ok

