###global: rangy###
app = require '../app.coffee'
_ = require 'lodash'


app.directive 'rmapsMacroEventHelper', ($rootScope, $log, $timeout, textAngularManager) ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    scope.mousex = 0
    scope.mousey = 0

    element.bind 'dragover', (e) ->
      scope.mousex = e.clientX
      scope.mousey = e.clientY

    # update macros while you type
    element.on 'keyup', (e) ->
      update = () ->
        scope.macroAction.whenTyped e
        ngModel.$commitViewValue()
        ngModel.$render()
      scope.$evalAsync update

    # set a handler on so it gets destroyed upon backspace
    element.on 'keydown', (e) ->
      update = () ->
        if e.keyCode == 8 # if backspace key...
          scope.macroAction.whenBackspaced e
          ngModel.$commitViewValue()
          ngModel.$render()
      scope.$evalAsync update

    $timeout ->
      scope.editor = textAngularManager.retrieveEditor 'wysiwyg'
      scope.editor?.scope?.$on 'rmaps-drag-end', (e, opts) ->
        scope.macroAction.whenDropped e


    scope.$on '$destroy', () ->
      element.unbind 'dragover', element
      element.unbind 'keyup', element
      element.unbind 'keydown', element

    $rootScope.$on 'rmaps-drag-end', (e) ->
      scope.editor.editorFunctions.focus()
      # percolate drag end event down so the editor hears it
      scope.editor.scope.$broadcast 'rmaps-drag-end'


app.directive 'rmapsMacroHelper', ($log, $rootScope, $timeout, $window, $document) ->
  $log = $log.spawn('mail:rmapsMacroHelper')
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    _doc = $document[0]

    # convert existing macros that aren't already styled
    $timeout ->
      # `checkExistingMacros` is important in case macro definitions change, this forces saved
      #   campaigns to re-evaluate "macro-ized" spans for validity
      ngModel.$setViewValue scope.checkExistingMacros()
      ngModel.$setViewValue scope.convertMacros()
      ngModel.$render()

    # wrap the macro markup within a textnode in a span that can be styled
    scope.convertMacrosInSpan = (textnode, offset, macro, exchange=false) ->
      range = rangy.createRange()
      range.setStart textnode, offset
      if exchange
        range.setEnd textnode, offset+macro.length
        range.deleteContents()
      el = angular.element("<span>#{macro}</span>")[0]
      scope.setMacroClass el
      range.insertNode el
      return el

    # determine if the node has been flagged as macro span (whether valid or not), by class
    # this is *not* macro validation
    scope.isMacroNode = (node) ->
      classedNode = if node.nodeType == 3 then node.parentNode else node
      # this regex accounts for classname with/without "-error" flag
      return /macro-display/.test(classedNode.className)

    # macro or not?
    scope.validateMacro = (macro) ->
      return _.contains(_.map(scope.macros), macro)

    # apply correct class to a new or existing macro node
    scope.setMacroClass = (node) ->
      if node.nodeType == 3
        classedNode = node.parentNode
        macro = node.data
      else
        classedNode = node
        macro = node.childNodes[0].data

      if scope.validateMacro macro
        if classedNode.classList.contains 'macro-display-error'
          classedNode.classList.remove 'macro-display-error'
        classedNode.classList.add 'macro-display'
      else
        if classedNode.classList.contains 'macro-display'
          classedNode.classList.remove 'macro-display'
        classedNode.classList.add 'macro-display-error'


    # generic recursive tree walker
    # provide collection, containerName, and a test function with a process function to run on child if test passes
    scope.walk = (collection, containerName, test, process) ->
      for child in collection
        if test(child)
          process(child)
        if containerName of child and child[containerName].length > 0
          scope.walk child[containerName], containerName, test, process


    # checks all "macro-ized" spans for validity
    scope.checkExistingMacros = () ->
      # DOM-ize our letter content for easier traversal/processing
      content = ngModel.$viewValue
      letterDoc = new DOMParser().parseFromString(content, 'text/html')

      # helper func passed to 'walk'
      _test = (n) ->
        return scope.isMacroNode(n)

      # helper func passed to 'walk'
      # re-tests macro for validity
      _process = (n) ->
        scope.setMacroClass(n)

      # apply test and processing to DOM-ized letter...
      scope.walk letterDoc.childNodes, 'childNodes', _test, _process

      # return the resulting content
      letterDoc.documentElement.innerHTML


    # convert unwrapped macro-markup into spans
    scope.convertMacros = () ->
      # DOM-ize our letter content for easier traversal/processing
      content = ngModel.$viewValue
      letterDoc = new DOMParser().parseFromString(content, 'text/html')

      # helper func passed to 'walk'
      _test = (n) ->
        return n?.nodeType == 3 && not scope.isMacroNode(n) && /{{.*?}}/.test(n.data)

      # helper func passed to 'walk'
      # pulls macro-markup from data of text node to convert to styled macro
      _process = (n) ->
        re = new RegExp(/{{(.*?)}}/g)
        # js list push/pop acts like lifo queue, useful here to process last child first (from behind)
        # since the element changes as we pass
        conversions = []
        s = n.data
        while m = re.exec(s)
          conversions.push [n, m.index, m[0]]
        while p = conversions.pop()
          scope.convertMacrosInSpan p[0], p[1], p[2], true

      # apply test and processing to DOM-ized letter...
      scope.walk letterDoc.childNodes, 'childNodes', _test, _process

      # return the resulting content
      letterDoc.documentElement.innerHTML


    # filter selected node for macros
    scope.macroFilter = (sel) ->
      # make macro span if it needs
      if /{{.*?}}/.test(sel.focusNode?.data)
        if not scope.isMacroNode(sel.focusNode)
          offset = sel.focusNode.data.indexOf('{{')
          macro = sel.focusNode.data.substring offset, sel.focusNode.data.indexOf('}}')+2
          newMacroEl = scope.convertMacrosInSpan sel.focusNode, offset, macro, true

          # trim/clean data
          sel.focusNode.data = sel.focusNode.data.trim()

          # add a new text node right after placement of new macro span (part of caret placement)
          nextTextElement = newMacroEl.nextSibling
          parent = newMacroEl.parentNode
          referenceNode = nextTextElement

          # reference node will be null if we're at the end of a <p>
          if !referenceNode?
            # for some reason here, raw space " " gets trimmed when at end of tag, so we need to add a nbsp
            # Still counts as space, and renders as such in wysiwyg and pdf
            newNode = _doc.createTextNode('\u00A0')
            parent.appendChild newNode
          else
            # if we're inside other text, just add the regular space (not &nbsp) to be consistent
            newNode = _doc.createTextNode(" ")
            parent.insertBefore newNode, referenceNode

          # procure a new range for (part of caret placement)
          range = rangy.createRange()
          range.setStartAndEnd(newNode, 1)

          # set selection, which sets the caret placement
          selection = rangy.getSelection()
          selection.removeAllRanges()
          selection.setSingleRange range

    scope.caretFromPoint = () ->
      # http://stackoverflow.com/questions/2444430/how-to-get-a-word-under-cursor-using-javascript
      if _doc.caretPositionFromPoint
        range = _doc.caretPositionFromPoint scope.mousex, scope.mousey
        textNode = range.offsetNode
        offset = range.offset
      else if _doc.caretRangeFromPoint
        range = _doc.caretRangeFromPoint scope.mousex, scope.mousey
        textNode = range.startContainer
        offset = range.startOffset
      return {range, textNode, offset}

    # act on macros when events occur
    scope.macroAction =
      whenDropped: (e) ->
        scope.editor.editorFunctions.focus() # make sure editor has focus on drop
        sel = $window.getSelection()
        e.targetScope.displayElements.text[0].focus()
        {range, textNode, offset} = scope.caretFromPoint()

        # macro-ize markup
        scope.convertMacrosInSpan textNode, offset, scope.macro

      whenTyped: (e) ->
        $log.debug -> "whenTyped, event:\n#{JSON.stringify e}"
        sel = rangy.getSelection()
        # while typing, filter for macros and wrap if necessary
        scope.macroFilter(sel)

        # alter macro class depending on validity of macro
        if sel?.focusNode?.data? and scope.isMacroNode sel.focusNode
          scope.setMacroClass sel.focusNode

      whenBackspaced: (e) ->
        sel = rangy.getSelection()
        maybeMacroSpan = sel.focusNode.parentNode

        # remove entire macro span if we backspace on it
        if scope.isMacroNode(maybeMacroSpan)
          sel.focusNode.parentNode.parentNode.removeChild(maybeMacroSpan)


    # helper for holding a macro value during drag-and-drop
    scope.setMacro = (macro) ->
      scope.macro = macro

app.directive 'rmapsPageBreakHelper', ($log, $timeout) ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    $log = $log.spawn('mail:pageBreakHelper')

    # This is fairly conservative to try and ensure a paragraph does not overlap the margin
    bottomMargin = (1.0*72)

    # Standard letter
    pxPerPage = (11*72)

    # The padding/margin needs to be set on the page-break (first) element of each page.
    topMargin = (0.5*72)

    # It isn't necessary to subtract the top margin as long as the nearest position:relative parent is at the top of the page
    topMarginFirstPage = 0 # (2.7*96)

    # The tag type to consider for page-breaks.
    tagName = element.attr('ta-default-wrap') || 'p'

    update = () ->
      toCheck = element.find(tagName)
      nextBreak = pxPerPage - topMarginFirstPage - bottomMargin
      for p, i in toCheck
        offset = p.offsetTop + p.clientHeight
        # $log.debug -> "##{i} next:#{nextBreak}px/#{(nextBreak/96).toFixed(2)}in offsetTop:#{p.offsetTop}px/#{(p.offsetTop/96).toFixed(2)}in " +
          # " clientHeight:#{p.clientHeight}px/#{(p.clientHeight/96).toFixed(2)}in total:#{offset}px/#{(offset/96).toFixed(2)}in"
        if (offset) >= nextBreak && i > 0 # The first paragraph on any page will never be pushed to the next page
          angular.element(p).addClass 'page-break'
          nextBreak = p.offsetTop + pxPerPage - bottomMargin
        else
          angular.element(p).removeClass 'page-break'

    element.on 'keyup', _.debounce () ->
      scope.$evalAsync update
    , 100

    $timeout update, 500

    scope.$on '$destroy', () ->
      element.unbind 'keyup', element
