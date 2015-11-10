app = require '../app.coffee'

defaultHtml =
  'basicLetter':
    content: require('../../html/includes/mail/basic-letter-template.jade')()

    # document level adjustments we want to make for wysiwyg based on template type
    # add/remove special things into wysiwyg that we don't want to put in the original template, and not show up in letter
    # (requires explicit dom manipulation to set inner text, etc)
    # e.g. let's put informative text into the "return-address-window" element indicating where address will go
    addTemporaryHtml: (doc) ->
      # temporary indicator-text for address windows already placed in template

    removeTemporaryHtml: (doc) ->
      for clearDiv in ['return-address-window', 'recipient-address-window']
        div = doc.getElementById(clearDiv) || {childNodes: []}
        for child in div.childNodes
          child.remove()
      tmpBody = doc.createElement 'div'
      tmpBody.appendChild doc.children[0]
      tmpBody.innerHTML


defaultFinalStyle =
  'basicLetter':
    content: require '../../styles/mailTemplates/basic-letter/lob.styl'


getDefaultHtml = (type) ->
  return defaultHtml[type].content

getDefaultFinalStyle = (type) ->
  return defaultFinalStyle[type].content

app.factory 'rmapsMailTemplate', ($rootScope, $window, $log, $timeout, $q, $modal, $document, rmapsMailCampaignService, rmapsprincipal, rmapsevents) ->
  _doc = $document[0]

  class MailTemplate
    constructor: (@type) ->
      @defaultContent = getDefaultHtml(@type)
      @defaultFinalStyle = getDefaultFinalStyle(@type)
      @_setupWysiwygContent()
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

    _setupWysiwygContent: () =>
      $timeout () =>
        defaultHtml[@type].addTemporaryHtml(_doc)

    _createPreviewHtml: () =>
      #previewStyle = "body {box-shadow: 4px 4px 20px #888888;}"
      #previewStyle = "body {margin: 20px;}"
      previewStyle = "body {border: 1px solid black;}"
      "<html><head><title>#{@mailCampaign.name}</title><style>#{@style}#{previewStyle}</style></head><body>#{@mailCampaign.content}</body></html>"
      # @_createLobHtml()

    _createLobHtml: () =>
      letterDocument = new DOMParser().parseFromString @mailCampaign.content, 'text/html'
      lobContent = defaultHtml[@type].removeTemporaryHtml letterDocument
      "<html><head><title>#{@mailCampaign.name}</title><style>#{@style}</style></head><body>#{lobContent}</body></html>"

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
