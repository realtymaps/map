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


app.factory 'rmapsMailTemplate', ($window, $log, rmapsMailCampaignService) ->

  (templateType) ->
    @type = templateType
    @defaultContent = defaultHtml[@type]
    @defaultFinalStyle = defaultFinalStyle[@type]
    @content = @defaultContent
    @style = @defaultFinalStyle
    @title = "New Template"

    # @defaultTemplateStyle = defaultTemplateStyle[@type]

    @getDefaultContent = () =>
      @defaultContent

    @getDefaultFinalStyle = () =>
      @defaultFinalStyle

    # @getDefaultTemplateStyle = () =>
    #   @getDefaultTemplateStyle

    @_createPreviewHtml = () =>
      shadowStyle = ".letter-page {box-shadow: 4px 4px 20px #888888;}"
      # bodyPadding = "body {margin: 20px;}"
      "<html><head><title>#{@title}</title><style>#{@style}#{shadowStyle}</style></head><body>#{@content}</body></html>"

    @_createLobHtml = () =>
      "<html><head><title>#{@title}</title><style>#{@style}</style></head><body>#{@content}</body></html>"


    @openPreview = () =>
      preview = $window.open "", "_blank"
      preview.document.write @_createPreviewHtml()

    # @templateStyle = getDefaultTemplateStyle()

    @save = (campaign) =>
      campaign.content = @content
      rmapsMailCampaignService.create(campaign)
      .then (d) ->
        $log.debug "#### data sent, d:"
        $log.debug d

    @


