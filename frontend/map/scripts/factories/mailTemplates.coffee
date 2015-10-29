app = require '../app.coffee'
basicLetterHtml = require '../../html/includes/mail/basic-letter-template.jade'
basicLetterFinalStyle = require '../../styles/mailTemplates/basic-letter-lob.styl'
modalTemplate = require('../../html/views/templates/modal-snailPrice.tpl.jade')()
#basicLetterTemplateStyle = require '../../styles/mailTemplates/basic-letter-final.styl'

console.log "#### modalTemplate:"
console.log modalTemplate

defaultHtml =
  'basicLetter': basicLetterHtml()

defaultFinalStyle =
  'basicLetter': basicLetterFinalStyle

# defaultTemplateStyle =
#   'basicLetter': basicLetterTemplateStyle


app.factory 'rmapsMailTemplate', ($rootScope, $window, $log, $timeout, $q, $modal, rmapsMailCampaignService, rmapsprincipal) ->
  class MailTemplate
    constructor: (@type) ->
      $log.debug "#### what is @?"
      $log.debug @

      $log.debug "#### creating templateObj with type: #{@type}"
      @defaultContent = defaultHtml[@type]
      @defaultFinalStyle = defaultFinalStyle[@type]
      @style = @defaultFinalStyle
      @user =
        userID: null
      @mailCampaign =
        auth_user_id: 7
        name: 'New Mailing'
        count: 1
        status: 'pending'
        content: @defaultContent
        project_id: 1
      rmapsprincipal.getIdentity()
      .then (identity) =>
        @user.userId = identity.user.id
        # should be populated from identity
        @senderData =
          name: "Justin Taylor"
          address_line1: '2000 Bashford Manor Ln'
          address_line2: ''
          address_city: "Louisville"
          address_state: 'KY'
          address_zip: '40218'
          phone: "502-293-8000"
          email: "justin@realtymaps.com"


      @recipientData =
        property:
          rm_property_id = ''
        recipient:
          name: 'Dan Sexton'
          address_line1: 'Paradise Realty of Naples'
          address_line2: '201 Goodlette Rd S'
          address_city: 'Naples'
          address_state: 'FL'
          address_zip: '34102'
          phone: '(239) 877-7853'
          email: 'dan@mangrovebaynaples.com'

      $log.debug "#### returning @:"
      $log.debug @

    _createPreviewHtml: () =>
      shadowStyle = "body {box-shadow: 4px 4px 20px #888888;}"
      # bodyPadding = "body {margin: 20px;}"
      "<html><head><title>#{@mailCampaign.name}</title><style>#{@style}#{shadowStyle}</style></head><body>#{@mailCampaign.content}</body></html>"

    _createLobHtml: () =>
      "<html><head><title>#{@mailCampaign.name}</title><style>#{@style}</style></head><body>#{@mailCampaign.content}</body></html>"

    openPreview: () =>
      preview = $window.open "", "_blank"
      preview.document.write @_createPreviewHtml()

    save: () =>
      rmapsMailCampaignService.create(@mailCampaign) # put?
      .then (d) ->
        $log.debug "#### data sent, d:"
        $log.debug d

    quote: () =>
      $log.debug "\n\n#### quote:"
      rmapsprincipal.getIdentity()
      .then (identity) ->
        $log.debug "#### rmapsprincipal"
        $log.debug identity
      $log.debug "#### price quote"

      $rootScope.lobData =
        content: @mailCampaign.content
        macros: {'name': 'Justin'}
        recipient: @recipientData.recipient
        sender: @senderData
      $rootScope.modalControl = {}
      $log.debug "#### body data:"
      $log.debug $rootScope.lobData
      $modal.open
        # templateUrl: 'modal-snailPrice.tpl.html'
        template: modalTemplate
        controller: 'rmapsModalSnailPriceCtrl'
        scope: $rootScope
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'


  # blankTemplate =
  #   mailCampaign:
  #     auth_user_id: 7
  #     name: 'New Mailing'
  #     count: 1
  #     status: 'pending'
  #     content: ''
  #     project_id: 1

  # setTemplateType = (templateType) ->
  #   deferred = $q.defer()
  #   $log.debug "#### rmapsMailTemplate service, templateType:"
  #   $log.debug templateType
  #   @type = templateType
  #   # @title = "New Template"


  #   # @defaultTemplateStyle = defaultTemplateStyle[@type]

  #   @getDefaultContent = () =>
  #     @defaultContent

  #   @getDefaultFinalStyle = () =>
  #     @defaultFinalStyle

  #   # @getDefaultTemplateStyle = () =>
  #   #   @getDefaultTemplateStyle



  #   @openPreview = () ->
  #     $log.debug "Preview..."
  #     # preview = $window.open "", "_blank"
  #     # # $timeout () ->
  #     # #   preview.document.title = "Preview"
  #     # preview.document.write @_createPreviewHtml()

  #   # @templateStyle = getDefaultTemplateStyle()

  #   @save = () =>
  #     rmapsMailCampaignService.create(@mailCampaign) # put?
  #     .then (d) ->
  #       $log.debug "#### data sent, d:"
  #       $log.debug d

  #   deferred.resolve(@)
  #   deferred.promise
  #   # # $log.debug "#### this (@):"
  #   # # $log.debug @
  #   # @getTemplateObj = () =>
  #   #   $timeout () =>
  #   #     return @


