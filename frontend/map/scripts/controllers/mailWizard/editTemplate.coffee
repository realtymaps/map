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

    # looping like this doesn't work, i get 6 options for "white" instead.. some kind of reference issue since it leaves off with white
    # for color in [['Black','#000000'],['Blue','#0000ff'],['Green','#00ff00'],['Red', '#ff0000'],['Yellow','#ffff00'],['White','#ffffff']]
    #   console.log color
    #   taRegisterTool "text#{color[0]}",
    #     buttontext: color[0]
    #     class: "btn btn-circle color-#{color[0].toLowerCase()}"
    #     action: () ->
    #       console.debug "$editor:"
    #       console.debug this.$editor()
    #       this.$editor().wrapSelection 'forecolor', "#{color[0].toLowerCase()}"
    #     activeState: (el) ->
    #       return el[0].color == "#{color[1]}"

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


    taRegisterTool 'fontHelvetica',
      buttontext: 'Helvetica'
      class: 'btn btn-text'
      display: '<label> Helvetica'
      action: () ->
        this.$editor().wrapSelection 'fontName', 'Helvetica'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /font-family: Helvetica/.test(el[0].attributes.style.textContent)

    taRegisterTool 'fontTimesNewRoman',
      buttontext: 'Times New Roman'
      class: 'btn btn-text'
      display: '<label> Times New Roman'
      action: () ->
        this.$editor().wrapSelection 'fontName', 'TimesNewRoman'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /font-family: TimesNewRoman/.test(el[0].attributes.style.textContent)

    taRegisterTool 'fontGillSans',
      buttontext: 'Gill Sans'
      class: 'btn btn-text'
      display: '<label> Gill Sans'
      action: () ->
        this.$editor().wrapSelection 'fontName', 'Gill Sans'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /font-family: 'Gill Sans'/.test(el[0].attributes.style.textContent)

    taRegisterTool 'fontGeorgia',
      buttontext: 'Georgia'
      class: 'btn btn-text'
      display: '<label> Georgia'
      action: () ->
        this.$editor().wrapSelection 'fontName', 'Georgia'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /font-family: Georgia/.test(el[0].attributes.style.textContent)


    taRegisterTool 'textBlack',
      buttontext: 'Black'
      class: 'btn btn-circle color-black'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'black'
      activeState: (el) ->
        node = el[0]
        while node.parentNode? and not /.*?letter-page-content-text.*?/.test(node.parentNode.className)
          if node.attributes.style?.textContent? && /color: black/.test(node.attributes.style.textContent)
            return true
          node = node.parentNode
        return false

    taRegisterTool 'textBlue',
      buttontext: 'Blue'
      class: 'btn btn-circle color-blue'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'blue'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /color: blue/.test(el[0].attributes.style.textContent)

    taRegisterTool 'textGreen',
      buttontext: 'Green'
      class: 'btn btn-circle color-green'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'green'
      activeState: (el) ->
        #node = el
        return el[0].attributes.style?.textContent? && /color: green/.test(el[0].attributes.style.textContent)

    taRegisterTool 'textRed',
      buttontext: 'Red'
      class: 'btn btn-circle color-red'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'red'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /color: red/.test(el[0].attributes.style.textContent)

    taRegisterTool 'textYellow',
      buttontext: 'Yellow'
      class: 'btn btn-circle color-yellow'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'yellow'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /color: yellow/.test(el[0].attributes.style.textContent)

    taRegisterTool 'textWhite',
      buttontext: 'White'
      class: 'btn btn-circle color-white'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'white'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /color: white/.test(el[0].attributes.style.textContent)


    return taOptions
  ]
