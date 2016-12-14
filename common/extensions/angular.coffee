_ =  require 'lodash'

if window?.angular?

  parents = (element, propToSearch, searchStr, isFirst = false) ->
    pars = []
    curParent = _.first(element.parent())

    condition = ->
      if isFirst && pars.length
        doBail = true
      curParent? && curParent?.tagName != 'HTML' && !doBail

    while condition()
      if curParent[propToSearch].contains(searchStr)
        pars.push curParent
      curParent = curParent.parentNode

    pars

  #NOTE if we keep digging down this rabbit hole just pull in JQuery
  if !angular.element::parentsByClass?
    angular.element::parentsByClass = (toFindStr, isFirst) ->
      parents(@, 'className', toFindStr, isFirst)
  else
    console.warn "angular.element::parentsByClass: already defined"

  if !angular.element::parentsById?
    angular.element::parentsById = (toFindStr, isFirst) ->
      parents(@, 'id', toFindStr, isFirst)
  else
    console.warn "angular.element::parentsById: already defined"


  # copied from angular private functions
  if !angular.getBlockNodes
    angular.getBlockNodes = getBlockNodes = (nodes) ->
      # TODO(perf): update `nodes` instead of creating a new object?
      node = nodes[0]
      endNode = nodes[nodes.length - 1]
      blockNodes = undefined
      i = 1
      while node != endNode and (node = node.nextSibling)
        if blockNodes or nodes[i] != node
          if !blockNodes
            blockNodes = angular.element([].slice.call(nodes, 0, i))
          blockNodes.push node
        i++
      blockNodes or nodes
  else
    console.warn "angular.getBlockNodes: already defined"
