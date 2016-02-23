###globals angular, inject###
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

describe 'rmapsLeafletDrawDirectiveCtrlDefaultsService', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    angular.module('rmapsMapApp')
    .config ($provide) ->
      $provide.decorator 'rmapsLeafletDrawDirectiveCtrlDefaultsService', ($delegate) ->
        angular.extend $delegate.drawContexts, toExtend
        angular.extend $delegate.idToDefaultsMap,
          sketchDraw:
            classes:
              span:
                pen: 'crap'

        $delegate

    inject (_$rootScope_, _rmapsLeafletDrawDirectiveCtrlDefaultsService_) =>
      @rootScope = _$rootScope_
      @subject = _rmapsLeafletDrawDirectiveCtrlDefaultsService_

  it 'exists', ->
    expect(@subject).to.be.ok

  describe "drawContexts", ->

    it 'exist', ->
      @subject.drawContexts.should.be.ok

    it 'should be extended', ->
      @subject.drawContexts.sketchDraw.should.be.ok
      @subject.drawContexts.sketchDraw.should.be.eql toExtend.sketchDraw

  describe 'get', ->
    it 'works with divType atts.id overrides', ->
      fetched = @subject.get
        id: 'sketchDraw'
        subContext: 'classes'
        divType: 'span'
        drawContext: 'pen'

      fetched.should.be.equal 'crap'
