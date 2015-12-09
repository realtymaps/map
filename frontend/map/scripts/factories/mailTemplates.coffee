app = require '../app.coffee'

app.factory 'rmapsMailTemplate', ($rootScope, $window, $log, $timeout, $q, $modal, $document, rmapsMailCampaignService, rmapsprincipal, rmapsevents, rmapsMailTemplateTypeService) ->
  _doc = $document[0]

  class MailTemplate
    constructor: (@type) ->
      @defaultContent = rmapsMailTemplateTypeService.getDefaultHtml(@type)

      # @_setupWysiwygContent()

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
        # use data from identity for @senderData info as needed
        @user.userId = identity.user.id
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

    # _tearDown: () =>
    #   # so far we are only "tearing down" stuff that we know of that could exist for all templateTypes, but
    #   # if a special tearDown becomes needed for a specific templateType, add a templateType-level routine that
    #   # can be referenced from rmapsMailTemplateTypeService and executed here



    # _setupWysiwygContent: () =>
    #   $timeout () =>
    #     rmapsMailTemplateTypeService.setUp(@type, _doc)

    _createPreviewHtml: () =>
      #previewStyle = "body {box-shadow: 4px 4px 20px #888888;}"
      #previewStyle = "body {margin: 20px;}"
      #previewStyle = ".wysiwygOnly {display: block;}"

      # all the small class names added that the editor tools use on the content, like .fontSize12 {font-size: 12px}
      fragStyles = require '../../styles/mailTemplates/frags.styl'
      # previewStyle = "body {position: relative; width: 8.5in; height: 11in; margin: 0; padding: 0; color: black; border: 1px solid black;}"
      previewStyle = "body {border: 1px solid black;}"

      "<html><head><title>#{@mailCampaign.name}</title><style>#{fragStyles}#{previewStyle}</style></head><body class='letter-editor'>#{@mailCampaign.content}</body></html>"
      # @_createLobHtml()

    _createLobHtml: () =>
      fragStyles = require '../../styles/mailTemplates/frags.styl'
      #letterDocument = new DOMParser().parseFromString @mailCampaign.content, 'text/html'
      #lobContent = rmapsMailTemplateTypeService.tearDown(@type, letterDocument)
      "<html><head><title>#{@mailCampaign.name}</title><style>#{fragStyles}</style></head><body>#{lobContent}</body></html>"

    openPreview: () =>
      preview = $window.open "", "_blank"
      preview.document.write @_createPreviewHtml()

    save: () =>
      rmapsMailCampaignService.create(@mailCampaign) # put? upsert?
      .then (d) =>
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "Mail campaign \"#{@mailCampaign.name}\" saved.", type: 'rm-success' }

    quote: () =>
      $rootScope.lobData =
        content: @_createLobHtml()
        macros: {'name': 'Justin'}
        recipient: @recipientData.recipient
        sender: @senderData
      $rootScope.modalControl = {}
      $modal.open
        template: require('../../html/views/templates/modal-snailPrice.tpl.jade')()
        controller: 'rmapsModalSnailPriceCtrl'
        scope: $rootScope
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'
