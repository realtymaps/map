###globals angular, inject###
describe 'rmapsLeafletDrawDirectiveCtrlDefaultsService', ->
  toExtend =
    sketchDraw: [
      'polyline'
      'square'
      'circle'
      'polygon'
      'text'
      'edit'
      'trash'
    ]

  beforeEach ->
    angular.mock.module('rmapsMapApp')
    angular.module('rmapsMapApp').config ($provide) ->
      $provide.decorator 'rmapsLeafletDrawDirectiveCtrlDefaultsService', ($delegate) ->
        angular.extend $delegate.drawContexts, toExtend

    inject (_$rootScope_, _rmapsLeafletDrawDirectiveCtrlDefaultsService_) =>
      @rootScope = _$rootScope_
      @subject = _rmapsLeafletDrawDirectiveCtrlDefaultsService_

  it 'should be extended', ->
    @subject.drawContexts.sketchDraw.should.be.ok
