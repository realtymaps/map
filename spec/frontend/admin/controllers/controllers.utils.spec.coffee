###globals angular, inject###

describe 'controller.utils', ->
  describe 'rmapsUtilsFipsCodesCtrl', ->
    beforeEach ->
      angular.mock.module('rmapsAdminApp')

      inject ($controller, $rootScope, $q, digestor, rmapsFipsCodesService) =>
        @digestor = digestor
        @rmapsFipsCodesService = rmapsFipsCodesService
        @$controller = $controller
        @$rootScope = $rootScope
        @scope = @$rootScope.$new()
        @subject = $controller('rmapsUtilsFipsCodesCtrl', $scope: @scope)

    it 'exists', ->
      @subject.should.be.ok

    describe 'dependency rmapsFipsCodesService' , ->
      it 'getAllMlsCodes must function exist', ->
        @rmapsFipsCodesService.getAllMlsCodes.should.be.a 'function'
