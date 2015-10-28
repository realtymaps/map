app = require '../app.coffee'
basicLetterHtml = require '../../html/includes/mail/basic-letter-template.jade'
basicLetterFinalStyle = require '../../styles/mailTemplates/basic-letter-lob.styl'
#basicLetterTemplateStyle = require '../../styles/mailTemplates/basic-letter-final.styl'

defaultHtml =
  'basicLetter': basicLetterHtml()

defaultFinalStyle =
  'basicLetter': basicLetterFinalStyle

# defaultTemplateStyle =
#   'basicLetter': basicLetterTemplateStyle


app.factory 'rmapsMailTemplate', ($window, $log, $timeout, $q, rmapsMailCampaignService) ->
  class MailTemplate
    constructor: (@type) ->
      $log.debug "#### what is @?"
      $log.debug @

      $log.debug "#### creating templateObj with type: #{@type}"
      @defaultContent = defaultHtml[@type]
      @defaultFinalStyle = defaultFinalStyle[@type]
      @style = @defaultFinalStyle
      @mailCampaign =
        auth_user_id: 7
        name: 'New Mailing'
        count: 1
        status: 'pending'
        content: @defaultContent
        project_id: 1
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

    send: () =>
      $log.debug "#### send!!!!!"

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


