app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl', ($rootScope, $scope, $state, $log, $window, $timeout, rmapsprincipal, rmapsMailTemplate, textAngularManager) ->
  #templateHtml = require "../../../html/includes/mail/#{$scope.$parent.templateName}-template.jade"
  # templateHtml = require '../../../html/includes/mail/basic-letter-template.jade'
  # templatePath = '../../../html/includes/mail/basic-letter-template.jade'
  # templateHtml = require templatePath
  # $log.debug "#### templateHtml:"
  # $log.debug templateHtml()
  # $log.debug "#### templateStyle:"
  # $log.debug templateStyle

  #template = rmapsMailTemplateService($scope.$parent.templateType)
  templateObj = rmapsMailTemplate($scope.$parent.templateType)
  # $log.debug "#### templateObj.content:"
  # $log.debug templateObj.content
  # $log.debug "#### templateObj.style:"
  # $log.debug templateObj.style
  $log.debug "textAngularManager:"
  $log.debug textAngularManager

  # editorScope = textAngularManager.retrieveEditor('wysiwyg').scope

  # console.log "#### editorScope:"
  # console.log editorScope
  # $timeout () ->
  #   editorScope.displayElements.text.trigger 'focus'

  $scope.focusMe = (scope) ->
    $log.debug "#### focusMe(), scope:"
    $log.debug scope

  $scope.isreadonly = () ->
    true

  $scope.makeToolbar01 = (args) ->
    $log.debug "making toolbar01..."
    $log.debug "args:"
    $log.debug args
    return []
  # textAngularManager.registerToolbar({name: 'testToolbar01'})
  # textAngularManager.registerToolbar({name: 'testToolbar02'})
  $scope.data =
    htmlcontent: templateObj.content

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
  $provide.decorator 'taOptions', ['$document', 'taRegisterTool', '$delegate', '$timeout', 'textAngularManager', ($document, taRegisterTool, taOptions, $timeout, textAngularManager) ->
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

    taRegisterTool 'fontHelvetica',
      buttontext: 'Helvetica'
      class: 'btn btn-text'
      action: () ->
        this.$editor().wrapSelection 'fontName', 'Helvetica'
      activeState: (el) ->
        console.log "fontHelvetica, el:"
        console.log el
        return el[0].attributes.style?.textContent? && /font-family: Helvetica/.test(el[0].attributes.style.textContent)

    taRegisterTool 'fontTimesNewRoman',
      buttontext: 'Times New Roman'
      class: 'btn btn-text'
      action: () ->
        this.$editor().wrapSelection 'fontName', 'TimesNewRoman'
      activeState: (el) ->
        console.log "fontTimesNewRoman, el:"
        console.log el
        return el[0].attributes.style?.textContent? && /font-family: TimesNewRoman/.test(el[0].attributes.style.textContent)


    taRegisterTool 'textBlack',
      buttontext: 'Black'
      class: 'btn btn-circle color-black'
      action: () ->
        this.$editor().wrapSelection 'forecolor', 'black'
      activeState: (el) ->
        return el[0].attributes.style?.textContent? && /color: black/.test(el[0].attributes.style.textContent)

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

    console.debug "taOptions:"
    console.debug taOptions

    return taOptions
  ]

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
