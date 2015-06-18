app = require '../app.coffee'

app.service 'rmapsDragDrop', [ '$rootScope', ($rootScope) ->
  _src = null
  _target = null
  dragStart: (src) ->
    $rootScope.$emit 'rmaps-drag-start'
    _src = src
  dragEnd: (src) ->
    $rootScope.$emit 'rmaps-drag-end'
  dragEnter: (target) ->
    _target = target
  getSrc: () ->
    _src
  getTarget: () ->
    _target
]

app.directive 'rmapsDraggable', [ 'rmapsDragDrop', (rmapsDragDrop) ->
    {
      restrict: 'A'
      scope: rmapsDraggable: '=', rmapsDraggableCollection: '='
      link: (scope, el, attrs) ->
        angular.element(el).attr 'draggable', 'true'

        el.bind 'dragstart', (e) ->
          rmapsDragDrop.dragStart
            el: el
            model: scope.rmapsDraggable
            collection: scope.rmapsDraggableCollection

        el.bind 'dragend', (e) ->
          rmapsDragDrop.dragEnd
            el: el
            model: scope.rmapsDraggable
            collection: scope.rmapsDraggableCollection

        el.bind 'dragenter', (e) ->
          rmapsDragDrop.dragEnter scope.rmapsDraggable
    }
]

.directive 'rmapsDroppable', [ '$rootScope', 'rmapsDragDrop', ($rootScope, rmapsDragDrop) ->
  {
    restrict: 'A'
    scope: onDrop: '&', onDrag: '&', rmapsDroppable: '='
    link: (scope, el, attrs) ->
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

        $rootScope.$emit 'rmaps-drag-end'
        angular.element(e.target).removeClass 'rmaps-drag-over'

        scope.onDrop()(
          rmapsDragDrop.getSrc(),
          {
            el: el
            collection: scope.rmapsDroppable
          },
          rmapsDragDrop.getTarget()
        )

      $rootScope.$on 'rmaps-drag-start', ->
        # console.log 'rmaps-drag-start'
        angular.element(el).addClass 'rmaps-drop-target'

      $rootScope.$on 'rmaps-drag-end', ->
        # console.log 'rmaps-drag-end'
        angular.element(el).removeClass 'rmaps-drop-target'
        angular.element(el).removeClass 'rmaps-drag-over'
  }
]