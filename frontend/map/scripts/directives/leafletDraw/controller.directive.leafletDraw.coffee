###globals angular###
app = require '../../app.coffee'

app.service 'rmapsLeafletDrawDirectiveCtrlDefaults', () ->
  drawContexts = [
    'pen'
    'polyline'
    'square'
    'circle'
    'polygon'
    'text'
    'redo'
    'undo'
    'trash'
  ]
  ###
    Attrs.id map to allow custome subContext (cssClasses, etc..)

    Will be exposed and open to abuse (no add, remove etc.)
  ###
  idToDefaultsMap = {}

  _spanCssCls = 'icon'

  defaults =
    classes:
      button:
        default: 'button btn btn-transparent nav-btn'
      span:
        default: _spanCssCls
        pen: _spanCssCls + ' icon-note-pen'
        polyline: _spanCssCls + ' icon-polyline'
        square: _spanCssCls + ' icon-android-checkbox-outline-blank'
        circle: _spanCssCls + ' icon-android-radio-button-off'
        polygon: _spanCssCls + ' icon-polygon'
        text: _spanCssCls + ' icon-text-create'
        redo: _spanCssCls + ' icon-redo2'
        undo: _spanCssCls + ' icon-undo'
        trash: _spanCssCls + ' fa fa-trash-o'


  get = (opts) ->
    #not using onMissingArgs as this might become an OS lib
    ['subContext', 'divType', 'drawContext'].forEach (thing) ->
      if !opts[thing]
        throw new Error "#{thing} required"

    {id, divType, subContext, drawContext} = opts

    maybeIdDivTypeContext = idToDefaultsMap?[id]?[subContext]?[divType]
    maybeIdDrawContext = maybeIdDivTypeContext?[drawContext]

    #work our way down to most specific to generalized
    maybeIdDrawContext or
    maybeIdDivTypeContext or
    defaults?[subContext]?[divType]?[drawContext] or
    defaults?[subContext]?[divType]?.default or #we should have something here
    '' #worst case as undefined will kill ng-class and iterate forever


  createContexts = (divType) ->
    getClass: (drawContext, id) ->
      get({divType, subContext: 'classes', drawContext, id})

    click: (drawContext, id) ->
      get({divType, subContext: 'clicks', drawContext, id})?()

  explicitGets =
    button: createContexts 'button'
    span: createContexts 'span'

  #return all internals to allow them to be overriden for different behavior
  {defaults, get, idToDefaultsMap, explicitGets, drawContexts}

#simple binding where the logic is mainly driven by the above service
app.controller 'rmapsLeafletDrawDirectiveCtrl', ($scope, $log, rmapsLeafletDrawDirectiveCtrlDefaults) ->
  {explicitGets, drawContexts} = rmapsLeafletDrawDirectiveCtrlDefaults

  scopeContext = (divType) ->
    getClass: (drawContext) ->
      ret = explicitGets[divType].getClass(drawContext, $scope.attrsId)
      ret

    click: (drawContext) ->
      ret = explicitGets[divType].click(drawContext, $scope.attrsId)
      ret

  angular.extend $scope,
    button: scopeContext 'button'
    span: scopeContext 'span'
    drawContexts: drawContexts
