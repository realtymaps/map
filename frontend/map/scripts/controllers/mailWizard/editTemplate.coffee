app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl', ($rootScope, $scope, $state, $log, $window, rmapsprincipal, rmapsMailTemplate, textAngularManager) ->
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
  $provide.decorator 'taOptions', ['taRegisterTool', '$delegate', (taRegisterTool, taOptions) ->
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

    # for color in ['Black','Blue','Green','Red','Yellow','White']
    #   console.log color
    #   taRegisterTool "text#{color}",
    #     #iconclass: "fa fa-square red",
    #     #display: "<label class='btn btn-circle color-#{color.toLowerCase()}' ng-model='radioFontColorModel' btn-radio=\"'#{color.toLowerCase()}'\">#{color}</label>"
    #     display: "<button type='button' class='btn btn-circle color-#{color.toLowerCase()}'>#{color}</button>"
    #     action: () ->
    #       console.debug "$editor:"
    #       console.debug this.$editor()
    #       this.$editor().wrapSelection 'forecolor', color.toLowerCase()


    taRegisterTool "textBlack",
      #iconclass: "fa fa-square red",
      #display: "<label class='btn btn-circle color-#{color.toLowerCase()}' ng-model='radioFontColorModel' btn-radio=\"'#{color.toLowerCase()}'\">#{color}</label>"
      #display: "<button type='button' class='btn btn-circle color-black'>Black</button>"
      buttontext: 'Black'
      class: "btn btn-circle color-black"
      action: () ->
        console.debug "$editor:"
        console.debug this.$editor()
        this.$editor().wrapSelection 'forecolor', 'black'
      activeState: (el) ->
        console.debug "el:"
        console.debug el
        console.debug "this:"
        console.debug this
        return el[0].color == "#000000"


    taRegisterTool 'textRed',
      #iconclass: "fa fa-square red",
      #display: "<button type='button' class='btn btn-circle color-red'>Red</button>"
      buttontext: 'Red'
      class: "btn btn-circle color-red"
      action: () ->
        console.debug "$editor:"
        console.debug this.$editor()
        this.$editor().wrapSelection 'forecolor', 'red'
      activeState: (el) ->
        console.debug "el:"
        console.debug el
        console.debug "this:"
        console.debug this
        return el[0].color == "#ff0000"



    # taOptions.toolbar[1].push 'colourRed'

    # taRegisterTool 'textBlue',
    #   iconclass: "fa fa-square blue",
    #   action: () ->
    #     this.$editor().wrapSelection 'forecolor', 'blue'
    # # taOptions.toolbar[1].push 'colourBlue'
    console.debug "taOptions:"
    console.debug taOptions

    return taOptions
  ]

# app.config ($provide) ->
#   $provide.decorator 'taOptions', ['taRegisterTool', '$delegate', (taRegisterTool, taOptions) ->
#     console.debug "taOptions:"
#     console.debug taOptions
#   ]
