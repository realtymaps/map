###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplate', ($rootScope, $window, $log, $timeout, $q, $modal, rmapsMailCampaignService,
rmapsprincipal, rmapsevents, rmapsMailTemplateTypeService, rmapsUsStates) ->

  $log = $log.spawn 'map:mailTemplate'
  # is exposed for binding
  senderData = {}
  mailCampaign = {}

  create = (newMail = {}) ->
    defaults =
      auth_user_id: null
      name: 'New Mailing'
      count: 0
      status: 'pending'
      content: null
      lob_content: null
      project_id: 1
      sender_info: null
      template_type: ""
      recipients: [
        rm_property_id: '00000_00000000000_000'
        name: 'Dan Sexton'
        address_line1: 'Paradise Realty of Naples'
        address_line2: '201 Goodlette Rd S'
        address_city: 'Naples'
        address_state: 'FL'
        address_zip: '34102'
        phone: '(239) 877-7853'
        email: 'dan@mangrovebaynaples.com'
      ]

    _.defaults newMail, defaults

  create()

  # private structures
  _user =
    userID: null

  _getContent = () ->
    if !mailCampaign.content?
      mailCampaign.content = rmapsMailTemplateTypeService.getDefaultHtml()
    mailCampaign.content

  _setContent = (content) ->
    mailCampaign.content = content

  _setLobContent = () ->
    mailCampaign.lob_content = _createLobHtml()


  _senderIsSet = () ->
    return (Object.keys(senderData).length > 0)

  _procureSenderData = () ->
    if _senderIsSet()
      return $q.when senderData

    rmapsprincipal.getIdentity()
    .then (identity) ->
      rmapsUsStates.getById(identity.user.us_state_id)
      .then (state) ->
        _user.userId = identity.user.id
        mailCampaign.auth_user_id = identity.user.id
        senderData =
          first_name: identity.user.first_name
          last_name: identity.user.last_name
          company: null
          address_line1: identity.user.address_1
          address_line2: identity.user.address_2
          address_city: identity.user.city
          address_state: state?.code
          address_zip: identity.user.zip
          phone: identity.user.work_phone
          email: identity.user.email

        senderData

  _getSenderData = () ->
    _procureSenderData()

  _getLobSenderData = (origSender) ->
    # https://lob.com/docs#addresses
    lobSenderData = _.cloneDeep origSender
    lobSenderData.name = "#{lobSenderData.first_name} #{lobSenderData.last_name}"
    delete lobSenderData.first_name
    delete lobSenderData.last_name
    lobSenderData


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

  _setTemplateType = (type) ->
    mailCampaign.template_type = type
    mailCampaign.content = rmapsMailTemplateTypeService.getHtml(type)

##### PUBLIC
  senderData: senderData
  mailCampaign: mailCampaign

  createPreviewHtml: _createPreviewHtml
  createLobHtml: _createLobHtml

  setTemplateType: _setTemplateType
  procureSenderData: _procureSenderData
  getSenderData: _getSenderData
  getContent: _getContent
  setContent: _setContent

  openPreview: () ->
    preview = $window.open "", "_blank"
    preview.document.write _createPreviewHtml()

  load: (campaignId) ->
    rmapsMailCampaignService.get id: campaignId
    .then (campaigns) ->
      mailCampaign = campaigns[0] if campaigns.length

  save: () ->
    promise = null
    if !_senderIsSet() # sender must be set at least with defaults in order to save campaign
      promise = _procureSenderData()
    else
      promise = $q.when(senderData)

    promise
    .then (sender) ->
      mailCampaign.sender_info = _getLobSenderData(sender)
      if not mailCampaign.id?
        delete mailCampaign.id
        profile = rmapsprincipal.getCurrentProfile()
        mailCampaign.project_id = profile.project_id

        op = rmapsMailCampaignService.create(mailCampaign)
        .then ({data}) ->
          mailCampaign.id = data[0]
          $log.debug "campaign #{mailCampaign.id} created"
          $rootScope.$emit rmapsevents.alert.spawn, { msg: "Mail campaign \"#{mailCampaign.name}\" saved.", type: 'rm-success' }
      else
        op = rmapsMailCampaignService.update(mailCampaign)
        .then ({data}) ->
          $log.debug "campaign #{data.id} updated"

  quote: () ->
    _getLobSenderData().then (lobSenderData) ->
      $rootScope.lobData =
        content: _createLobHtml()
        macros: {'name': 'Justin'}
        recipient: mailCampaign.recipients[0]
        sender: lobSenderData
      $rootScope.modalControl = {}
      $modal.open
        template: require('../../html/views/templates/modal-snailPrice.tpl.jade')()
        controller: 'rmapsModalSnailPriceCtrl'
        scope: $rootScope
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'
