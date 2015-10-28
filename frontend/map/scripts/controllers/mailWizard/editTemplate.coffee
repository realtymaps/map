app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl', ($rootScope, $scope, $state, $log, $window, $timeout, $document, rmapsprincipal, rmapsMailTemplate, textAngularManager, rmapsMainOptions) ->
  #templateHtml = require "../../../html/includes/mail/#{$scope.$parent.templateName}-template.jade"
  # templateHtml = require '../../../html/includes/mail/basic-letter-template.jade'
  # templatePath = '../../../html/includes/mail/basic-letter-template.jade'
  # templateHtml = require templatePath
  # $log.debug "#### templateHtml:"
  # $log.debug templateHtml()
  # $log.debug "#### templateStyle:"
  # $log.debug templateStyle
  # $scope.caret = 
  #template = rmapsMailTemplateService($scope.$parent.templateType)
  
  templateObj = rmapsMailTemplate($scope.$parent.templateType)
  # $log.debug "#### templateObj.content:"
  # $log.debug templateObj.content
  # $log.debug "#### templateObj.style:"
  # $log.debug templateObj.style
  $log.debug "textAngularManager:"
  $log.debug textAngularManager
  editor = {}
  $timeout () ->
    $log.debug "#### taTools:"
    $log.debug taTools
    editor = textAngularManager.retrieveEditor('wysiwyg')
    $log.debug "#### editor:"
    $log.debug editor
    editor.editorFunctions.focus()
    editor.scope.$on 'rmaps-drag-end', (e, opts) ->
      editor.editorFunctions.focus()
      # editor.triggerElementSelect(e, )
      console.log "#### EDITOR rmaps-drag-end, e:"
      console.log e
      console.log "#### EDITOR rmaps-drag-end, opts:"
      console.log opts
      console.log "#### EDITOR rmaps-drag-end, $scope.macro:"
      console.log $scope.macro


      sel = $window.getSelection()
      # console.log "#### EDITOR rmaps-drag-end, sel:"
      # console.log sel
      # console.log "#### EDITOR rmaps-drag-end, event targetScope:"
      # console.log e.targetScope.displayElements.text[0]
      e.targetScope.displayElements.text[0].focus()
      # $log.debug "mousex:"
      # $log.debug $scope.mousex
      # $log.debug "mousey:"
      # $log.debug $scope.mousey
      # $log.debug "$document:"
      # $log.debug $document[0]
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
      $log.debug "range:"
      $log.debug range
      $log.debug "this sel:"
      $log.debug sel
      el = angular.element "<span class='macro-display'>#{$scope.macro}</span>"
      range.insertNode el[0]

      #editor.scope.wrapSelection('insertHTML', " #{$scope.macro} ")

      #range.insertNode( $document.createTextNode("ABUNCHTEXT") )

  # $scope.insertMacroCode = (textNode, offset) ->
  #   if !offset?





    # editor.scope.$on 'rmaps-drag-end', (e) ->
    #   console.log "#### EDITOR rmaps-drag-end, e:"
    #   console.log e
    #   sel = $window.getSelection()
    #   console.log "#### EDITOR rmaps-drag-end, sel:"
    #   console.log sel
  $scope.mousex
  $scope.mousey

  $scope.setMacro = (macro) ->
    $log.debug "setMacro(), macro:"
    $log.debug macro
    $scope.macro = macro

  $scope.dropMacro = (e) ->
    $log.debug "#### dropMacro()"
    $log.debug "#### e:"
    $log.debug e

  $scope.eventMacro = (type) ->
    (e) ->
      $scope.mousex = e.clientX
      $scope.mousey = e.clientY
      # $log.debug "#### eventMacro(), type:"
      # $log.debug type
      # $log.debug "#### eventMacro()"
      # $log.debug "#### e:"
      # $log.debug e
      # editor.editorFunctions.focus()
      # sel = $window.getSelection()
      # console.log "#### eventMacro() , sel:"
      # console.log sel


  $scope.textEditorSetup = () ->
    $log.debug "textEditorSetup"
    (arg1) ->
      $log.debug "textEditorSetup operation, arg1:"
      $log.debug arg1
      # arg1[0].ondragend = $scope.eventMacro('ondragend')
      # arg1[0].ondrag = $scope.eventMacro('ondrag')
      # arg1[0].onclick = $scope.eventMacro('onclick')
      arg1[0].ondragover = $scope.eventMacro('ondragover')
      # arg1[0].ondrop = $scope.eventMacro('ondrop')
      # arg1[0].onmouseup = $scope.eventMacro('onmouseup')
      # arg1[0].ondragend (e) ->
      # # arg1[0].addEventListener 'rmaps-drag-end', (e) ->
      #   $log.debug "#### textEditorSetup drag-end, e:"
      #   $log.debug e


  $scope.htmlEditorSetup = () ->
    $log.debug "htmlEditorSetup"
    (arg1) ->
      $log.debug "htmlEditorSetup operation, arg1:"
      $log.debug arg1
      # arg1[0].ondragend = $scope.eventMacro('ondragend')
      # arg1[0].ondrag = $scope.eventMacro('ondrag')
      # arg1[0].onclick = $scope.eventMacro('onclick')
      # arg1[0].ondragover = $scope.eventMacro('ondragover')
      # arg1[0].ondrop = $scope.eventMacro('ondrop')
      # arg1[0].onmouseup = $scope.eventMacro('onmouseup')
      # arg1[0].ondragend (e) ->
      # # arg1[0].addEventListener 'rmaps-drag-end', (e) ->
      #   $log.debug "#### textEditorSetup drag-end, e:"
      #   $log.debug e
    

  # editorScope = textAngularManager.retrieveEditor('wysiwyg').scope

  # console.log "#### editorScope:"
  # console.log editorScope
  # $timeout () ->
  #   editorScope.displayElements.text.trigger 'focus'

  $scope.getCursorPosition = () ->
    sel = $window.getSelection()
    $log.debug "getCursorPosition, sel:"
    $log.debug sel
    range = {}
    if sel.getRangeAt && sel.rangeCount
      return sel.getRangeAt(0)

  # function getCursorPosition() {
  #     var sel, range;
  #     sel = window.getSelection();
  #     if (sel.getRangeAt && sel.rangeCount) {
  #         return sel.getRangeAt(0);
  #     }
  # }
  $scope.insertTextAtPosition = (text, range) ->
    $log.debug "insertTextAtPosition, text:"
    $log.debug text
    $log.debug "insertTextAtPosition, range:"
    $log.debug range
    range.insertNode(document.createTextNode(text))

  # function insertTextAtPosition(text, range) {
  #     range.insertNode(document.createTextNode(text));
  # }

  $scope.mouseUpEvent = (e) ->
    $log.debug "#### mouseUpEvent(), e:"
    $log.debug e
    sel = $window.getSelection()
    $log.debug "#### mouseUpEvent, caret:"
    $log.debug sel


  $rootScope.$on 'rmaps-drag-end', (e) ->
    $log.debug "#### rmaps-drag-end, e:"
    $log.debug e
    editor.editorFunctions.focus()
    editor.scope.$broadcast 'rmaps-drag-end'
    sel = $window.getSelection()
    $log.debug "#### rmaps-drag-end, caret:"
    $log.debug sel
    $log.debug "rangy:"
    $log.debug rangy

  # $rootScope.$on 'mouseup', (e) ->
  #   console.log "#### mouseup, e:"
  #   console.log e
  #   sel = $window.getSelection()
  #   $log.debug "#### sel:"
  #   $log.debug sel

  $scope.macros =
    rmapsMainOptions.mail.macros

  $scope.macro = ""

  $scope.focusMe = (scope) ->
    $log.debug "#### focusMe(), scope:"
    $log.debug scope

  $scope.isreadonly = () ->
    true

  $scope.mailCampaign =
    auth_user_id: 7
    name: 'testCampaign'
    count: 1
    status: 'pending'
    content: ''
    project_id: 1

  $scope.saveContent = () ->
    templateObj.content = $scope.mailCampaign.content
    templateObj.save($scope.mailCampaign)
    #_createLobHtml
    # rmapsMailCampaignService.post()
    # .then (d) ->
    #   $log.debug "#### data sent, d:"
    #   $log.debug d

  $scope.makeToolbar01 = (args) ->
    $log.debug "making toolbar01..."
    $log.debug "args:"
    $log.debug args
    return []
  # textAngularManager.registerToolbar({name: 'testToolbar01'})
  # textAngularManager.registerToolbar({name: 'testToolbar02'})
  $scope.data =
    htmlcontent: templateObj.content

  $scope.$watch 'data.htmlcontent', (newC, oldC) ->
    # $log.debug "watch, newC:"
    # $log.debug newC
    # $log.debug "watch, oldC:"
    # $log.debug oldC
    sel = rangy.getSelection()
    $log.debug "sel:"
    $log.debug sel



    if /.*?{{.*?}}.*?/.test(newC)

      i1 = newC.indexOf '{{'
      i2 = newC.indexOf '}}'
      # $log.debug "#### newC:"
      # $log.debug newC
      $log.debug "i1, i2:"
      $log.debug "#{i1}, #{i2}"

    if sel?.focusNode?.data? && /macro-display/.test(sel.focusNode.parentNode.className) && not _.contains(_.map($scope.macros), sel.focusNode.data)
      $log.debug "#### DNE!"
      parent = sel.focusNode.parentNode
      $log.debug "#### parent:"
      $log.debug parent
      parent.remove()
      # $timeout () ->
        # sel.refresh()
        # $scope.$apply()


  $scope.applyTemplateClass = () ->
    "#{$scope.$parent.templateType}-body"

  $scope.doPreview = () ->
    templateObj.content = $scope.data.htmlcontent
    templateObj.openPreview()

  # $scope.preview = () ->
  #   $log.debug "#### preview()"
  #   preview = $window.open "", "_blank"
  #   preview.document.write "<html><body>#{$scope.data.htmlcontent}</body></html>"

app.config ($provide) ->
  $provide.decorator 'taTools', ['$delegate', (taTools) ->
    console.debug "taTools:"
    console.debug taTools
    # taTools.undo.iconclass = ''
    # taTools.undo.buttontext = 'Undo'
    # taTools.undo =
    #   iconclass: ''
    #   buttontext: 'Undo'

    return taTools
  ]

app.config ($provide) ->
  $provide.decorator 'taOptions', ['$document', 'taRegisterTool', '$delegate', '$timeout', 'textAngularManager', 'rmapsMainOptions',
  ($document, taRegisterTool, taOptions, $timeout, textAngularManager, rmapsMainOptions) ->
    console.log "document:"
    console.log $document
    $document[0].execCommand('styleWithCSS', false, true)
    # taOptions.toolbar = [
    #   ['bold', 'italics', 'underline'],
    #   ['ul', 'ol']
    # ]
    console.debug "#### taOptions"
    taRegisterTool 'test',
      buttontext: 'Test',
      action: () ->
        console.debug "$editor:"
        console.debug this.$editor()
        #this.$editor().
        alert 'Test Pressed'



    # taOptions.classes =
    #   toolbar: ''
    # taOptions.toolbar[0].push 'test'

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


# .fontSize10
#   font-size (10px / $scale-factor)

    # taRegisterTool 'undo',
    #   buttontext: "10pt",
    #   class: "btn btn-white",
    #   display: "<label> 10pt"
    #   action: () ->
    #     # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
    #     classApplier = rangy.createClassApplier 'fontSize10',
    #       tagNames: ["*"],
    #       normalize: true
    #     classApplier.toggleSelection()
    #   activeState: (el) ->
    #     console.log "fontSize10"
    #     console.log el

    macros = rmapsMainOptions.mail.macros
    taRegisterTool 'macroTool',
      buttontext: "macro-tool",
      class: "btn btn-white",
      display: "<label> macro-tool"
      action: () ->
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
        classApplier = rangy.createClassApplier 'macro-display',
          tagNames: ["*"],
          normalize: true
        classApplier.toggleSelection()
      activeState: (el) ->
        # console.log "#### macro-tool, el[0].innerText:"
        # console.log el[0].innerText
        # console.log "#### macro-tool, _.map(macros):"
        # console.log _.map(macros)
        return _.contains(_.map(macros), el[0].innerText)


    taRegisterTool 'fontSize10',
      buttontext: "10pt",
      class: "btn btn-white",
      display: "<label> 10pt"
      action: () ->
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
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
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
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
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
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
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
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
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
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
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
        console.log "#### tool 'this':"
        console.log this
        classApplier = rangy.createClassApplier 'fontSize18',
          tagNames: ["*"],
          normalize: true
        console.log "#### classApplier:"
        console.log classApplier
        classApplier.toggleSelection()
      activeState: (el) ->
        return el[0].className == "fontSize18"

    taRegisterTool 'fontSize20',
      buttontext: "20pt",
      class: "btn btn-white",
      display: "<label> 20pt"
      action: () ->
        # this.$editor().wrapSelection('formatBlock', '<span class="fontSize10">');
        console.log "#### tool 'this':"
        console.log this
        classApplier = rangy.createClassApplier 'fontSize20',
          tagNames: ["*"],
          normalize: true
        console.log "#### classApplier:"
        console.log classApplier
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
        while not /.*?letter-page-content-text.*?/.test(node.parentNode.className)
          # console.log "textBlack node:"
          # console.log node

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

    # taRegisterTool 'undo',
    #   iconclass: ""
    #   buttontext: 'Undo'
    #   class: 'btn btn-text'
      # action: () ->
      #   this.$editor().wrapSelection 'forecolor', 'white'
      # activeState: (el) ->
      #   return el[0].attributes.style?.textContent? && /color: white/.test(el[0].attributes.style.textContent)



    # taRegisterTool 'specialBackspace',
    #   buttontext: 'Special Backspace'
    #   action: (a) ->
    #     console.debug "#### specialBackspace action, a:"
    #     console.debug a
    #     console.debug "backspace action"
    #   activeState: (el) ->
    #     console.debug "backspace, el:"
    #     console.debug el
    #   commandKeyCode: "extendedBackspace"

    # shouldBackspace = (element) ->
    #   if 

    # taOptions.keyMappings = [
    #   commandKeyCode: "extendedBackspace"
    #   testForKey: (event) ->
    #     console.debug "#### backspace key test, event:"
    #     console.debug event
    #     editorScope = textAngularManager.retrieveEditor('wysiwyg').scope
    #     console.log "#### editorScope:"
    #     console.log editorScope

    #     #if event.keyCode == 8
          
    #     return true

    # ]
    # taOptions.toolbar[1].push 'colourRed'

    # taRegisterTool 'textBlue',
    #   iconclass: "fa fa-square blue",
    #   action: () ->
    #     this.$editor().wrapSelection 'forecolor', 'blue'
    # # taOptions.toolbar[1].push 'colourBlue'
    # taOptions.setup.textEditorSetup = ($element) ->
    #   console.log "#### element:"
    #   console.log $element
    #   $timeout -> $element.trigger('focus')
    # textAngularManager.updateToolDisplay 'undo',
    #   iconclass: ""
    #   buttontext: "Undo"
    #   display: "<label>"

    # console.debug "taOptions:"
    # console.debug taOptions

    return taOptions
  ]


# app.config ($provide) ->

# app.directive 'textAngular', ($parse, $timeout, textAngularManager) ->
#   link: (scope, element, attributes) ->
#     shouldFocus = $parse(attributes.focus)(scope)
#     if !shouldFocus
#       return
#     $timeout () ->
#       console.log "#### triggering focus"
#       editorScope = textAngularManager.retrieveEditor(attributes.name).scope
#       console.log "#### editorScope:"
#       console.log editorScope
#       editorScope.displayElements.text[0].trigger 'focus'
#     , 0, false


# app.config ($provide) ->
#   $provide.decorator 'taOptions', ['taRegisterTool', '$delegate', (taRegisterTool, taOptions) ->
#     console.debug "taOptions:"
#     console.debug taOptions
#   ]
