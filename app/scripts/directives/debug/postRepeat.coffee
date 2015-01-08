#shamelessly copied from
#http://tech.small-improvements.com/2013/09/10/angularjs-performance-with-large-lists/
#https://gist.github.com/rkgarg/7232175
app = require '../../app.coffee'
directiveName = 'rmapsPostRepeat'
app.directive directiveName, [ 'Logger'.ourNs(),
  ($log) ->
    postRepeat = {}

    scope:
      options: '='

    link: (scope, element, attrs) ->
      attrScope = scope.$parent
      #root parent to all ng-repeats (encapsulating div or whatever)
      parent = attrScope.$parent
      if attrScope.$first
        # lastTime can be updated anywhere if to reset counter at some
        #action if ng-repeat is not getting started from $first
        postRepeat[parent.$id] =
          lastTime: new Date()

        parent.$on '$destroy', ->
          delete postRepeat[parent.$id]
      if scope.options?
        opts = scope.options
        #use init function (via attribute binding (basically options)) to
        # pass the postRepeat object on so the lastTime can be rest
        opts.init(postRepeat[parent.$id],scope) if opts.init? and angular.isFunction opts.init

      if attrScope.$last
        scope.$evalAsync ->
          $log.debug "## DOM rendering list took: " +
            (new Date() - postRepeat[parent.$id].lastTime) + " ms"
          doDelete = if not opts?.doDeleteLastTime? then true else opts?.doDeleteLastTime
          delete postRepeat[parent.$id] if doDelete
]
