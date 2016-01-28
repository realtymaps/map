###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplate', ($rootScope, $window, $log, $timeout, $q, $modal, rmapsMailCampaignService,
rmapsprincipal, rmapsevents, rmapsMailTemplateTypeService, rmapsUsStates) ->

  $log = $log.spawn 'map:mailTemplate'
  mailCampaign = null

  campaignDefaults =
    id: null
    auth_user_id: null
    lob_batch_id: null
    name: 'New Mailing'
    count: 0
    status: 'pending'
    content: null
    template_type: ''
    lob_content: null
    sender_info: null
    recipients: []
    submitted: null

  create = (newMail = {}, newSender = {}) ->
    mailCampaign = _.defaults newMail, campaignDefaults
    senderData = newSender

  create()

  _getCampaign = () ->
    mailCampaign

  _getContent = () ->
    if !mailCampaign.content?
      mailCampaign.content = rmapsMailTemplateTypeService.getDefaultHtml()
    mailCampaign.content

  _setContent = (content) ->
    mailCampaign.content = content

  _setLobContent = () ->
    mailCampaign.lob_content = _createLobHtml()

  _setRecipients = (recipients) ->
    mailCampaign.recipients = recipients

  _getSenderData = () ->
    return $q.when mailCampaign.sender_info if !_.isEmpty mailCampaign.sender_info

    rmapsprincipal.getIdentity()
    .then (identity) ->
      rmapsUsStates.getById(identity.user.us_state_id)
      .then (state) ->
        mailCampaign.auth_user_id = identity.user.id
        mailCampaign.sender_info =
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

  _getLobSenderData = () ->
    # https://lob.com/docs#addresses
    lobSenderData = _.cloneDeep mailCampaign.sender_info
    lobSenderData.name = "#{lobSenderData.first_name ? ''} #{lobSenderData.last_name ? ''}".trim()
    delete lobSenderData.first_name
    delete lobSenderData.last_name
    lobSenderData

  _getLobRecipientData = () ->
    return null unless mailCampaign.recipients?.length

    _.map mailCampaign.recipients, (r) ->
      name: r.name ? "Current Resident"
      address_line1: "#{r.street_address_num ? ''} #{r.street_address_name ? ''}"
      address_line2: r.street_address_unit ? ''
      address_city: r.city ? ''
      address_state: r.state ? ''
      address_zip: r.zip ? ''

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
  create: create
  createPreviewHtml: _createPreviewHtml
  createLobHtml: _createLobHtml

  setTemplateType: _setTemplateType
  setRecipients: _setRecipients
  getSenderData: _getSenderData
  getContent: _getContent
  setContent: _setContent
  getCampaign: _getCampaign

  openPreview: () ->
    preview = $window.open "", "_blank"
    preview.document.write _createPreviewHtml()

  load: (campaignId) ->
    rmapsMailCampaignService.get id: campaignId
    .then (campaigns) ->
      mailCampaign = campaigns[0] if campaigns.length

  save: () ->
    _getSenderData()
    .then () ->
      toSave = _.pick mailCampaign, _.keys(campaignDefaults)
      toSave.recipients = JSON.stringify toSave.recipients

      if not toSave.id?
        delete toSave.id
        profile = rmapsprincipal.getCurrentProfile()
        toSave.project_id = profile.project_id

        op = rmapsMailCampaignService.create(toSave)
        .then ({data}) ->
          mailCampaign.id = data[0]
          $log.debug "campaign #{mailCampaign.id} created"
          $rootScope.$emit rmapsevents.alert.spawn, { msg: "Mail campaign \"#{mailCampaign.name}\" saved.", type: 'rm-success' }
      else
        op = rmapsMailCampaignService.update(toSave)
        .then ({data}) ->
          $log.debug "campaign #{data[0]} updated"

  quote: () ->
    $modal.open
      template: require('../../html/views/templates/modal-snailPrice.tpl.jade')()
      controller: 'rmapsModalSnailPriceCtrl'
      keyboard: false
      backdrop: 'static'
      windowClass: 'snail-modal'
      resolve:
        lobData: ->
          campaign: _getCampaign()
          file: _createLobHtml()
          macros: name: 'Justin'
          recipients: _getLobRecipientData()
          from: _getLobSenderData()
