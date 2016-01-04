app = require '../app.coffee'

app.service 'rmapsMailTemplate', ($rootScope, $window, $log, $timeout, $q, $modal, rmapsMailCampaignService,
rmapsprincipal, rmapsevents, rmapsMailTemplateTypeService, rmapsGeoLocations) ->

  # exposed for binding
  senderData = {}
  mailCampaign =
    auth_user_id: null
    name: 'New Mailing'
    count: 0
    status: 'pending'
    content: null
    lob_content: null
    project_id: 1
    sender_info: null

  _user =
    userID: null

  _type = ""

  _recipientData =
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

  # _state = rmapsGeoLocations.getState(17)
  # .then (code) ->
  #   $log.debug "\n\n#### _state, code:"
  #   $log.debug code

  #$q.all()

  _senderIsSet = () ->
    return (Object.keys(senderData).length > 0)

  _getContent = () ->
    if !mailCampaign.content?
      mailCampaign.content = rmapsMailTemplateTypeService.getDefaultHtml()
    mailCampaign.content

  _setContent = (content) ->
    mailCampaign.content = content

  _setLobContent = () ->
    mailCampaign.lob_content = _createLobHtml()

  _procureSenderData = () ->
    if _senderIsSet()
      $log.debug "\n\n######## _procureSenderData: (senderData exists) sender data:"
      $log.debug senderData
      return $q.when senderData

    rmapsprincipal.getIdentity()
    .then (identity) ->
      $log.debug "\n\n######## _procureSenderData: identity:"
      $log.debug JSON.stringify(identity)
      # $log.debug identity.toString()

      rmapsGeoLocations.getState(identity.user.us_state_id)
      .then (state) ->
        # use data from identity for @senderData info as needed
        $log.debug "\n\n######## _procureSenderData: state:"
        $log.debug JSON.stringify(state)

        _user.userId = identity.user.id
        mailCampaign.auth_user_id = identity.user.id
        senderData =
          first_name: identity.user.first_name
          last_name: identity.user.last_name
          company: null
          address_line1: identity.user.address_1
          address_line2: identity.user.address_2
          address_city: identity.user.city
          address_state: state.code
          address_zip: identity.user.zip
          phone: identity.user.work_phone
          email: identity.user.email

        $log.debug "\n\n######## _procureSenderData: (senderData gotten via identity) sender data:"
        # $log.debug _senderData
        $log.debug JSON.stringify(senderData)

        senderData

  _createPreviewHtml = () ->
    # all the small class names added that the editor tools use on the content, like .fontSize12 {font-size: 12px}
    fragStyles = require '../../styles/mailTemplates/template-frags.styl'
    classStyles = require '../../styles/mailTemplates/template-classes.styl'
    previewStyles = "body {border: 1px solid black;}"
    "<html><head><title>#{mailCampaign.name}</title><style>#{fragStyles}#{classStyles}#{previewStyles}</style></head><body class='letter-editor'>#{mailCampaign.content}</body></html>"

  _createLobHtml = () ->
    fragStyles = require '../../styles/mailTemplates/template-frags.styl'
    classStyles = require '../../styles/mailTemplates/template-classes.styl'
    "<html><head><title>#{mailCampaign.name}</title><style>#{fragStyles}#{classStyles}</style></head><body class='letter-editor'>#{mailCampaign.content}</body></html>"

  _getSenderData = () ->
    _procureSenderData()

  _getLobSenderData = (origSender) ->
    # _procureSenderData().then (sender) ->

    # https://lob.com/docs#addresses
    lobSenderData = _.cloneDeep origSender
    $log.debug "\n\n#### lobSenderData:"
    $log.debug lobSenderData
    lobSenderData.name = "#{lobSenderData.first_name} #{lobSenderData.last_name}"
    delete lobSenderData.first_name
    delete lobSenderData.last_name
    lobSenderData


##### PUBLIC
  senderData: senderData
  mailCampaign: mailCampaign

  setTemplateType: (type) ->
    mailCampaign.content = rmapsMailTemplateTypeService.getHtml(type)

  procureSenderData: _procureSenderData
  getSenderData: _getSenderData
  # getLobSenderData: _getLobSenderData
  getContent: _getContent
  setContent: _setContent

  openPreview: () ->
    preview = $window.open "", "_blank"
    preview.document.write _createPreviewHtml()

  save: () ->
    promise = null
    if !_senderIsSet() # sender must be set at least with defaults in order to save campaign
      promise = _procureSenderData()
    else
      promise = $q.when(senderData)

    promise
    .then (sender) ->
      mailCampaign.sender_info = _getLobSenderData(sender)
      # if !mailCampaign.id?
      #   delete mailCampaign.id
      #   op = rmapsMailCampaignService.create(mailCampaign)
      # else
      #   op = rmapsMailCampaignService.update(mailCampaign)
      op = rmapsMailCampaignService.create(mailCampaign)
      op # put? upsert?
      .then (d) ->
        $log.debug "\n\n######## save(), update response:"
        $log.debug d
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "Mail campaign \"#{mailCampaign.name}\" saved.", type: 'rm-success' }

  quote: () ->
    _getLobSenderData().then (lobSenderData) ->
      $log.debug "\n\n######## quote() lobSenderData:"
      $log.debug lobSenderData
      $rootScope.lobData =
        content: _createLobHtml()
        macros: {'name': 'Justin'}
        recipient: _recipientData.recipient
        sender: lobSenderData
      $rootScope.modalControl = {}
      $modal.open
        template: require('../../html/views/templates/modal-snailPrice.tpl.jade')()
        controller: 'rmapsModalSnailPriceCtrl'
        scope: $rootScope
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'



  # class MailTemplate #MailCampaign
  #   constructor: () ->

  #     #@defaultContent = rmapsMailTemplateTypeService.getDefaultHtml(@type)
  #     @defaultContent = null

  #     @user =
  #       userID: null
  #     @mailCampaign =
  #       auth_user_id: null
  #       name: 'New Mailing'
  #       count: 1
  #       status: 'pending'
  #       content: @defaultContent
  #       project_id: 1

  #     rmapsprincipal.getIdentity()
  #     .then (identity) =>
  #       $log.debug "\n\n######## identity:"
  #       $log.debug identity
  #       # use data from identity for @senderData info as needed
  #       @user.userId = identity.user.id
  #       @senderData =
  #         first_name: identity.first_name
  #         last_name: identity.last_name
  #         company: null
  #         address_line1: identity.address_1
  #         address_line2: identity.address_2
  #         address_city: identity.city
  #         address_state: rmapsGeoLocations.getState(identity.us_state_id).code
  #         address_zip: identity.zip
  #         phone: identity.work_phone
  #         email: identity.email

  #     @recipientData =
  #       property:
  #         rm_property_id = ''
  #       recipient:
  #         name: 'Dan Sexton'
  #         address_line1: 'Paradise Realty of Naples'
  #         address_line2: '201 Goodlette Rd S'
  #         address_city: 'Naples'
  #         address_state: 'FL'
  #         address_zip: '34102'
  #         phone: '(239) 877-7853'
  #         email: 'dan@mangrovebaynaples.com'

  #   setTemplateType: (@type) ->
  #     @defaultContent = rmapsMailTemplateTypeService.getDefaultHtml(@type)

  #   getLobSenderData: () ->
  #     unless @senderData? then return
  #     # https://lob.com/docs#addresses
  #     lobSenderData = _.cloneDeep @senderData
  #     $log.debug "\n\n#### lobSenderData:"
  #     $log.debug lobSenderData
  #     lobSenderData.name = "#{lobSenderData.first_name} #{lobSenderData.last_name}"
  #     delete lobSenderData.first_name
  #     delete lobSenderData.last_name
  #     lobSenderData


  #   _createPreviewHtml: () =>
  #     # all the small class names added that the editor tools use on the content, like .fontSize12 {font-size: 12px}
  #     fragStyles = require '../../styles/mailTemplates/template-frags.styl'
  #     classStyles = require '../../styles/mailTemplates/template-classes.styl'
  #     previewStyles = "body {border: 1px solid black;}"
  #     "<html><head><title>#{@mailCampaign.name}</title><style>#{fragStyles}#{classStyles}#{previewStyles}</style></head><body class='letter-editor'>#{@mailCampaign.content}</body></html>"

  #   _createLobHtml: () =>
  #     fragStyles = require '../../styles/mailTemplates/template-frags.styl'
  #     classStyles = require '../../styles/mailTemplates/template-classes.styl'
  #     "<html><head><title>#{@mailCampaign.name}</title><style>#{fragStyles}#{classStyles}</style></head><body class='letter-editor'>#{@mailCampaign.content}</body></html>"

  #   openPreview: () =>
  #     preview = $window.open "", "_blank"
  #     preview.document.write @_createPreviewHtml()

  #   save: () =>
  #     rmapsMailCampaignService.create(@mailCampaign) # put? upsert?
  #     .then (d) =>
  #       $rootScope.$emit rmapsevents.alert.spawn, { msg: "Mail campaign \"#{@mailCampaign.name}\" saved.", type: 'rm-success' }

  #   quote: () =>
  #     $rootScope.lobData =
  #       content: @_createLobHtml()
  #       macros: {'name': 'Justin'}
  #       recipient: @recipientData.recipient
  #       sender: @getLobSenderData()
  #     $rootScope.modalControl = {}
  #     $modal.open
  #       template: require('../../html/views/templates/modal-snailPrice.tpl.jade')()
  #       controller: 'rmapsModalSnailPriceCtrl'
  #       scope: $rootScope
  #       keyboard: false
  #       backdrop: 'static'
  #       windowClass: 'snail-modal'
