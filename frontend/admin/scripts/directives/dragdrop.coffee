app = require '../app.coffee'

app.service 'rmapsDragDrop', [ '$rootScope', ($rootScope) ->
  _el = null
  dragStart: (el) ->
    console.log 'rmapsDragDrop: drag-start', el
    $rootScope.$emit 'rmaps-drag-start'
    _el = el
  dragEnd: (el) ->
    console.log 'rmapsDragDrop: drag-end', el
    $rootScope.$emit 'rmaps-drag-end'
  getEl: ->
    _el
]

app.directive 'rmapsDraggable', [ 'rmapsDragDrop', (rmapsDragDrop) ->
    {
      restrict: 'A'
      scope: {}
      link: (scope, el, attrs, controller) ->
        angular.element(el).attr 'draggable', 'true'
        el.bind 'dragstart', (e) ->
          # jQuery wraps the originalEvent
          dataTransfer = e.dataTransfer || e.originalEvent.dataTransfer
          rmapsDragDrop.dragStart(el)
        el.bind 'dragend', (e) ->
          rmapsDragDrop.dragEnd(el)
    }
]

.directive 'rmapsDroppable', [ '$rootScope', 'rmapsDragDrop', ($rootScope, rmapsDragDrop) ->
  {
    restrict: 'A'
    scope: onDrop: '&'
    link: (scope, el, attrs, controller) ->
      id = angular.element(el).attr('id')
      el.bind 'dragover', (e) ->
        e.preventDefault?()
        e.stopPropagation?()
        dataTransfer = e.dataTransfer || e.originalEvent.dataTransfer
        dataTransfer.dropEffect = 'move'
        false
      el.bind 'dragenter', (e) ->
        angular.element(e.target).addClass 'rmaps-drag-over'
      el.bind 'dragleave', (e) ->
        angular.element(e.target).removeClass 'rmaps-drag-over'
      el.bind 'drop', (e) ->
        e.preventDefault?()
        e.stopPropogation?()
        src = rmapsDragDrop.getEl()
        # jQuery wraps the originalEvent
        data = e.dataTransfer || e.originalEvent.dataTransfer
        if src
          el.append(src)
          scope.onDrop
            dragEl: src
            dropEl: el
      $rootScope.$on 'rmaps-drag-start', ->
        console.log 'rmaps-drag-start received'
        angular.element(el).addClass 'rmaps-drop-target'
      $rootScope.$on 'rmaps-drag-end', ->
        angular.element(el).removeClass 'rmaps-drop-target'
        angular.element(el).removeClass 'rmaps-drag-over'
  }
]