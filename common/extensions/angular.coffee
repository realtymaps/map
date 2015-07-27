if window?.angular?

  parents = (element, propToSearch, searchStr, isFirst = false) ->
    pars = []
    curParent = _.first(element.parent())

    condition = ->
      if isFirst && pars.length
        doBail = true
      curParent? && curParent?.tagName != "HTML" && !doBail

    while condition()
      if curParent[propToSearch].contains(searchStr)
        pars.push curParent
      curParent = curParent.parentNode

    pars

  #NOTE if we keep digging down this rabbit hole just pull in JQuery
  angular.element::parentsByClass = (toFindStr, isFirst) ->
    parents(@, 'className', toFindStr, isFirst)

  angular.element::parentsById = (toFindStr, isFirst) ->
    parents(@, 'id', toFindStr, isFirst)
