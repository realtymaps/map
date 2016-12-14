app = require '../app.coffee'
_ = require 'lodash'
rangy = require 'rangy'
config = require '../../../../common/config/commonConfig.coffee'


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

    # picky about keystroke actions on macro
    element.on 'keydown', (e) ->

      # remove macro on backspace
      # key / keyCode compatibilities: http://www.quirksmode.org/js/keys.html
      if e.keyCode == 8
        update = () ->
          scope.macroAction.whenBackspaced e
          ngModel.$commitViewValue()
          ngModel.$render()
        scope.$evalAsync update

      # suppress typing in macro
      else
        sel = rangy.getSelection()
        if scope.isMacroNode(sel.focusNode) || scope.isHighlightNode(sel.focusNode)
          # using for alphanumeric keys to suppress:
          # http://stackoverflow.com/questions/12052825/regular-expression-for-all-printable-characters-in-javascript
          if config.validation.alphanumeric.test(e.key)
            e.preventDefault()
            return false

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
      ngModel.$setViewValue scope.convertMacrosAndHighlights()
      ngModel.$render()


    #
    # General tools for operating on elements and dom
    #

    createSpan = (textnode, offset, text, options={}) ->
      range = rangy.createRange()
      range.setStart textnode, offset
      if options?.exchange # removes existing text to create new span in its place
        range.setEnd textnode, offset+text.length
        range.deleteContents()
      el = angular.element("<span>#{text}</span>")
      range.insertNode el[0]
      return el

    # generic recursive tree walker
    # provide collection, containerName, and a test function with a process function to run on child if test passes
    walk = (collection, containerName, test, process) ->
      for child in collection
        if test(child)
          process(child)
        if containerName of child and child[containerName].length > 0
          walk(child[containerName], containerName, test, process)

    textAngularWalker = (testFn, processFn) ->
      # DOM-ize our letter content for easier traversal/processing
      content = ngModel.$viewValue
      letterDoc = new DOMParser().parseFromString(content, 'text/html')

      # apply test and processing to DOM-ized letter...
      walk(letterDoc.childNodes, 'childNodes', testFn, processFn)

      # return the resulting content
      letterDoc.documentElement.innerHTML

    caretFromPoint = () ->
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


    #
    # element creation tools
    #

    # wrap the macro markup within a textnode in a span that can be styled
    scope.convertMacrosInSpan = (textnode, offset, macro, options={}) ->
      el = createSpan(textnode, offset, macro, options)
      scope.setMacroClass el
      return el

    # wrap the highlighted markup within a textnode in a span that can be styled
    scope.convertHighlightInSpan = (textnode, offset, highlight, options={}) ->
      el = createSpan(textnode, offset, highlight, options)
      scope.setHighlightClass el
      return el

    # apply correct class to a new or existing macro node
    scope.setMacroClass = (node) ->
      # ensure we handle an html node, even if given a jqLite iterable
      if node.length == 1 && node[0].nodeType?
        node = node[0]

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

    # apply highlight class to a node
    scope.setHighlightClass = (node) ->
      # ensure we handle an html node, even if given a jqLite iterable
      if node.length == 1 && node[0].nodeType?
        node = node[0]

      if node.nodeType == 3
        classedNode = node.parentNode
        macro = node.data
      else
        classedNode = node
        macro = node.childNodes[0].data

      classedNode.classList.add 'highlight-display'


    #
    # checks & validations
    #

    # determine if the node has been flagged as macro span (whether valid or not), by class
    # this is *not* macro validation
    scope.isMacroNode = (node) ->
      classedNode = if node.nodeType == 3 then node.parentNode else node
      # this regex accounts for classname with/without "-error" flag
      return /macro-display/.test(classedNode.className)

    # determine if node is a highlighted node
    scope.isHighlightNode = (node) ->
      classedNode = if node.nodeType == 3 then node.parentNode else node
      # this regex accounts for classname with/without "-error" flag
      return /highlight-display/.test(classedNode.className)

    # macro or not?
    scope.validateMacro = (macro) ->
      return _.contains(_.map(scope.macros), macro)


    #
    # methods for operating the entire document
    #

    # checks all "macro-ized" spans for validity
    scope.checkExistingMacros = () ->
      # helper func passed to 'walk'
      _test = (n) ->
        return scope.isMacroNode(n)

      # helper func passed to 'walk'
      # re-tests macro for validity
      _process = (n) ->
        scope.setMacroClass(n)

      # apply test and processing to DOM-ized letter...
      textAngularWalker(_test, _process)


    # convert unwrapped macro and highlight markup into spans
    # it's necessary to do both macros and highlights together since the order of creating spans in a single parent is important
    scope.convertMacrosAndHighlights = () ->
      # helper func passed to 'walk'
      _test = (n) ->
        return n?.nodeType == 3 && !scope.isMacroNode(n) && !scope.isHighlightNode(n) && /({{.*?}})|(\[\[.*?\]\])/.test(n.data)

      # helper func passed to 'walk'
      # pulls macro-markup from data of text node to convert to styled macro
      _process = (n) ->
        re = new RegExp(/({{(.*?)}})|(\[\[(.*?)\]\])/g)
        # js list push/pop acts like lifo queue, useful here to process last child first (from behind)
        # since the element changes as we pass
        conversions = []
        s = n.data
        while m = re.exec(s)
          conversions.push [n, m.index, m[0]]
        while p = conversions.pop()
          if /^{{.*?}}$/.test(p[2])
            scope.convertMacrosInSpan p[0], p[1], p[2], exchange: true
          else
            scope.convertHighlightInSpan p[0], p[1], p[2], exchange: true

      # apply test and processing to DOM-ized letter...
      textAngularWalker(_test, _process)


    #
    # event handlers, real-time manipulators
    #

    # real-time filter/update document text for macros (used when macros get typed, dragged, inserted, etc)
    scope.macroFilter = (sel) ->
      # make macro span if it needs
      if /{{.*?}}/.test(sel.focusNode?.data)
        if not scope.isMacroNode(sel.focusNode)
          offset = sel.focusNode.data.indexOf('{{')
          macro = sel.focusNode.data.substring offset, sel.focusNode.data.indexOf('}}')+2
          newMacroEl = scope.convertMacrosInSpan sel.focusNode, offset, macro, exchange: true

          # trim/clean data
          sel.focusNode.data = sel.focusNode.data.trim()

          # add a new text node right after placement of new macro span (part of caret placement)
          nextTextElement = newMacroEl[0].nextSibling
          parent = newMacroEl[0].parentNode
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

    # act on macros when events occur
    scope.macroAction =
      whenDropped: (e) ->
        scope.editor.editorFunctions.focus() # make sure editor has focus on drop
        sel = $window.getSelection()
        e.targetScope.displayElements.text[0].focus()
        {range, textNode, offset} = caretFromPoint()

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
        sibling = maybeMacroSpan.nextSibling

        # remove entire macro span if we backspace on it
        if scope.isMacroNode(maybeMacroSpan) || scope.isHighlightNode(maybeMacroSpan)
          sel.focusNode.parentNode.parentNode.removeChild(maybeMacroSpan)

          # necessary for avoiding the reappearing-span bug (https://realtymaps.atlassian.net/browse/MAPD-1333)
          if sibling
            range = rangy.createRange()
            range.setStartAndEnd(sibling, 0)
            selection = rangy.getSelection()
            selection.removeAllRanges()
            selection.setSingleRange range

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
