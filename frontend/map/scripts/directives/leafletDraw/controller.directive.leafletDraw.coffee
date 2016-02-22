###globals angular###
app = require '../../app.coffee'
directiveName = 'rmapsLeafletDrawDirectiveCtrl'

app.service "#{directiveName}DefaultsService", () ->
  drawContexts = [
    'pen'
    'polyline'
    'rectangle'
    'circle'
    'polygon'
    'text'
    'redo'
    'undo'
    'edit'
    'trash'
  ]
  ###
    Attrs.id map to allow custome subContext (cssClasses, etc..)

    Will be exposed and open to abuse (no add, remove etc.)
  ###
  idToDefaultsMap = {}

  _spanCssCls = 'icon'

  defaults =
    texts:
      button:
        default: ''
        cancel: 'Cancel'
    classes:
      button:
        default: 'button btn btn-transparent nav-btn'
        cancel: 'button btn btn-primary'
      span:
        pen: _spanCssCls + ' icon-note-pen'
        polyline: _spanCssCls + ' icon-polyline'
        rectangle: _spanCssCls + ' icon-android-checkbox-outline-blank'
        circle: _spanCssCls + ' icon-android-radio-button-off'
        polygon: _spanCssCls + ' icon-polygon'
        text: _spanCssCls + ' icon-text-create'
        redo: _spanCssCls + ' icon-redo2'
        undo: _spanCssCls + ' icon-undo'
        edit: _spanCssCls + ' fa fa-edit'
        trash: _spanCssCls + ' fa fa-trash-o'
        cancel: undefined


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
    getText: (drawContext, id) ->
      get({divType, subContext: 'texts', drawContext, id})

  explicitGets =
    button: createContexts 'button'
    span: createContexts 'span'

  getEvents = (id) ->
    drawContexts[id] or drawContexts

  getEventName = (id, drawContext) ->
    eventName = '' + directiveName
    [id, drawContext].forEach (name) ->
      eventName += ".#{name}"
    eventName

  allEvents = (id, cb) ->
    for c in getEvents(id)
      cb(getEventName(id, c))

  #return all internals to allow them to be overriden
  #for different behavior
  {
    defaults
    get
    idToDefaultsMap
    explicitGets
    drawContexts
    getEvents
    getEventName
    allEvents
  }


#simple binding where the logic is mainly driven by the above service
app.controller directiveName, ($scope, $log, rmapsLeafletDrawDirectiveCtrlDefaultsService) ->
  {getEventName, explicitGets, drawContexts} = rmapsLeafletDrawDirectiveCtrlDefaultsService

  scopeContext = (divType) ->
    getClass: (drawContext) ->
      ret = explicitGets[divType].getClass(drawContext, $scope.attrsId)
      ret

    getText: (drawContext) ->
      ret = explicitGets[divType].getText(drawContext, $scope.attrsId)
      ret

    click: (drawContext, event) ->
      $scope.$emit getEventName($scope.attrsId, drawContext), event

  angular.extend $scope,
    button: scopeContext 'button'
    span: scopeContext 'span'
    drawContexts: drawContexts
    disable: () ->
      $scope.enabled = false

  $scope.$watch 'attrsId', (newVal, oldVal) ->
    if newVal != oldVal and newVal?
      $scope.drawContexts = drawContexts[newVal]
