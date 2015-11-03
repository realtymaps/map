app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl', ($rootScope, $scope, $state, $log, $window, $timeout, $document, rmapsprincipal, rmapsMailTemplate, textAngularManager, rmapsMainOptions) ->

  # might move this object to the mailWizard (parent) scope to expose the members to all wizard steps for building the object
  $scope.templateObj = new rmapsMailTemplate($scope.$parent.templateType)

  editor = {}
  $timeout () ->
    editor = textAngularManager.retrieveEditor('wysiwyg')
    editor.editorFunctions.focus()
    editor.scope.$on 'rmaps-drag-end', (e, opts) ->
      sel = $window.getSelection()
      e.targetScope.displayElements.text[0].focus()

      # http://stackoverflow.com/questions/2444430/how-to-get-a-word-under-cursor-using-javascript
      if $document[0].caretPositionFromPoint
        range = $document[0].caretPositionFromPoint $scope.mousex, $scope.mousey
        textNode = range.offsetNode
        offset = range.offset
      else if $document[0].caretRangeFromPoint
        range = $document[0].caretRangeFromPoint $scope.mousex, $scope.mousey
        textNode = range.startContainer
        offset = range.startOffset

      # $log.debug "textNode:"
      # $log.debug textNode
      # $log.debug "offset:"
      # $log.debug offset

      range = rangy.createRange()
      range.setStart textNode, offset
      range.collapse true
      sel = rangy.getSelection()
      sel.setSingleRange range
      el = angular.element "<span class='macro-display'>#{$scope.macro}</span>"
      range.insertNode el[0]

  $scope.quoteAndSend = () ->
    $scope.templateObj.quote()

  $scope.setMacro = (macro) ->
    $log.debug "setMacro(), macro:"
    $log.debug macro
    $scope.macro = macro

  $scope.dropMacro = (e) ->
    $log.debug "#### dropMacro()"
    $log.debug "#### e:"
    $log.debug e

  $scope.eventMacro = (type) ->
    $log.debug "... listening for #{type}"
    (e) ->
      $scope.mousex = e.clientX
      $scope.mousey = e.clientY

  $scope.textEditorSetup = () ->
    (el) ->
      $log.debug "#### textEditorSetup operation, el:"
      $log.debug el
      # el[0].ondragend = $scope.eventMacro('ondragend')
      # el[0].ondrag = $scope.eventMacro('ondrag')
      # el[0].onclick = $scope.eventMacro('onclick')
      el[0].ondragover = $scope.eventMacro('ondragover') # updates mouse coords for macro placement in window
      # el[0].ondrop = $scope.eventMacro('ondrop')
      # el[0].onmouseup = $scope.eventMacro('onmouseup')

  $scope.htmlEditorSetup = () ->
    (el) ->
      $log.debug "#### htmlEditorSetup operation, el:"
      $log.debug el
      # el[0].ondragend = $scope.eventMacro('ondragend')
      # el[0].ondrag = $scope.eventMacro('ondrag')
      # el[0].onclick = $scope.eventMacro('onclick')
      # el[0].ondragover = $scope.eventMacro('ondragover')
      # el[0].ondrop = $scope.eventMacro('ondrop')
      # el[0].onmouseup = $scope.eventMacro('onmouseup')

  $rootScope.$on 'rmaps-drag-end', (e) ->
    editor.editorFunctions.focus()
    # percolate drag end event down so the editor hears it
    editor.scope.$broadcast 'rmaps-drag-end'

  $scope.macros =
    rmapsMainOptions.mail.macros

  $scope.macro = ""

  $scope.saveContent = () ->
    $scope.templateObj.save()

  $scope.data =
    htmlcontent: $scope.templateObj.mailCampaign.content

  # intercept html changes for updating things like removing macros, as well as save html data back to templateObj
  $scope.$watch 'data.htmlcontent', (newC, oldC) ->
    sel = rangy.getSelection()

    # process existing or typed macros (UNFINISHED)
    if /.*?{{.*?}}.*?/.test(newC)

      i1 = newC.indexOf '{{'
      i2 = newC.indexOf '}}'
      # $log.debug "#### newC:"
      # $log.debug newC
      # $log.debug "i1, i2:"
      # $log.debug "#{i1}, #{i2}"

    # if a macro-display element exists (which means it used to be valid macro) but 
    # is not among valid macros anymore (because that means it's being deleted), remove it completely
    if sel?.focusNode?.data? && /macro-display/.test(sel.focusNode.parentNode.className) && not _.contains(_.map($scope.macros), sel.focusNode.data)
      parent = sel.focusNode.parentNode
      parent.remove()
      #### reconnect text nodes (sometimes they appear disjoint in the markup)?

    # refresh content on $scope.templateObj
    $scope.templateObj.mailCampaign.content = $scope.data.htmlcontent

  $scope.applyTemplateClass = (qualifier = '') ->
    "#{$scope.$parent.templateType}#{qualifier}"

  $scope.doPreview = () ->
    $scope.templateObj.openPreview()

app.config ($provide) ->
  $provide.decorator 'taTools', ['$log', '$delegate', ($log, taTools) ->
    $log.debug "taTools:"
    $log.debug taTools
    return taTools
  ]

app.config ($provide) ->
  $provide.decorator 'taOptions', ['$log', '$document', 'taRegisterTool', '$delegate', '$timeout', 'textAngularManager', 'rmapsMainOptions',
  ($log, $document, taRegisterTool, taOptions, $timeout, textAngularManager, rmapsMainOptions) ->

    # helps HTML5 compatibility, which uses css instead of deprecated tags like <font>
    $document[0].execCommand('styleWithCSS', false, true)

    taRegisterTool 'fontSize10',
      buttontext: "10pt",
      class: "btn btn-white",
      display: "<label> 10pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize10',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize10"

    taRegisterTool 'fontSize12',
      buttontext: "12pt",
      class: "btn btn-white",
      display: "<label> 12pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize12',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize12"

    taRegisterTool 'fontSize13',
      buttontext: "13pt",
      class: "btn btn-white",
      display: "<label> 13pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize13',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize13"

    taRegisterTool 'fontSize14',
      buttontext: "14pt",
      class: "btn btn-white",
      display: "<label> 14pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize14',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize14"

    taRegisterTool 'fontSize16',
      buttontext: "16pt",
      class: "btn btn-white",
      display: "<label> 16pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize16',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize16"

    taRegisterTool 'fontSize18',
      buttontext: "18pt",
      class: "btn btn-white",
      display: "<label> 18pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize18',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize18"

    taRegisterTool 'fontSize20',
      buttontext: "20pt",
      class: "btn btn-white",
      display: "<label> 20pt"
      action: () ->
        classApplier = rangy.createClassApplier 'fontSize20',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize20"

    for font in ['Georgia','Gill Sans','Times New Roman','Helvetica']
      do (font) ->
        nospace = font.replace(/ /g,'')
        maybeQuoted = if / /.test(font) then "'#{font}'" else font
        r = new RegExp "font-family: #{maybeQuoted}"
        taRegisterTool "font#{nospace}",
          buttontext: font
          class: 'btn btn-text'
          display: "<label> #{font}"
          action: () ->
            this.$editor().wrapSelection 'fontName', font
          activeState: (el) ->
            return el[0].attributes.style?.textContent? && r.test(el[0].attributes.style.textContent)

    for color in ['Black','Blue','Green','Red','Yellow','White']
      do (color) ->
        taRegisterTool "text#{color}",
          buttontext: color
          class: "btn btn-circle color-#{color.toLowerCase()}"
          action: () ->
            this.$editor().wrapSelection 'forecolor', color.toLowerCase()
          activeState: (el) ->
            node = el[0]
            while node.parentNode? and not /.*?letter-page-content-text.*?/.test(node.parentNode.className)
              r = new RegExp "color: #{color.toLowerCase()}"
              if node.attributes.style?.textContent? && r.test(node.attributes.style.textContent)
                return true
              node = node.parentNode
            return false

    return taOptions
  ]
