###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplateService', ($rootScope, $window, $log, $timeout, $q, $modal, rmapsMailCampaignService,
rmapsPrincipalService, rmapsEventConstants, rmapsMailTemplateTypeService, rmapsUsStatesService) ->

  $log = $log.spawn 'mail:mailTemplate'
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
    $log.debug -> "Created mailCampaign:\n#{JSON.stringify(mailCampaign, null, 2)}"

  create()

  _getCampaign = () ->
    mailCampaign

  _setCampaign = (campaign) ->
    mailCampaign = campaign

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

    rmapsPrincipalService.getIdentity()
    .then (identity) ->
      rmapsUsStatesService.getById(identity.user.us_state_id)
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

  _createPreviewHtml = (content) ->
    # all the small class names added that the editor tools use on the content, like .fontSize12 {font-size: 12px}
    fragStyles = require '../../styles/mailTemplates/template-frags.styl'
    classStyles = require '../../styles/mailTemplates/template-classes.styl'
    previewStyles = "body {background-color: #FFF}"
    "<html><head><title>#{mailCampaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>" +
      "<style>#{fragStyles}#{classStyles}#{previewStyles}</style></head><body class='letter-body'>#{content}</body></html>"

  _createLobHtml = () ->
    fragStyles = require '../../styles/mailTemplates/template-frags.styl'
    classStyles = require '../../styles/mailTemplates/template-classes.styl'
    "<html><head><title>#{mailCampaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>" +
      "<style>#{fragStyles}#{classStyles}</style></head><body class='letter-body'>#{mailCampaign.content}</body></html>"

  _setTemplateType = (type) ->
    mailCampaign.template_type = type
    mailCampaign.content = rmapsMailTemplateTypeService.getHtml(type)

  _getCategory = () ->
    rmapsMailTemplateTypeService.getCategoryFromType(mailCampaign.template_type)

  _setStatus = (status) ->
    mailCampaign.status = status

  _isSent = () ->
    mailCampaign.status == 'sent'

##### PUBLIC
  create: create
  createPreviewHtml: _createPreviewHtml
  createLobHtml: _createLobHtml

  setTemplateType: _setTemplateType
  getCategory: _getCategory
  setRecipients: _setRecipients
  getSenderData: _getSenderData
  getContent: _getContent
  setContent: _setContent
  getCampaign: _getCampaign
  setCampaign: _setCampaign
  setStatus: _setStatus

  isSent: _isSent

  openPreview: () ->
    preview = $window.open "", "_blank"
    preview.document.write _createPreviewHtml()

  load: (campaignId) ->
    rmapsMailCampaignService.get id: campaignId
    .then (campaigns) ->
      $log.debug -> "Loaded mailCampaign:\n#{JSON.stringify(campaigns, null, 2)}"
      mailCampaign = campaigns[0] if campaigns.length

  save: () ->
    _getSenderData()
    .then () ->
      toSave = _.pick mailCampaign, _.keys(campaignDefaults)
      $log.debug -> "Saving mailCampaign:\n#{JSON.stringify(toSave, null, 2)}"
      toSave.recipients = JSON.stringify toSave.recipients

      profile = rmapsPrincipalService.getCurrentProfile()
      toSave.project_id = profile.project_id

      op = rmapsMailCampaignService.create(toSave) #upserts if not already created
      .then ({data}) ->
        $log.debug -> "Create data response:\n#{JSON.stringify(data, null, 2)}"
        mailCampaign.id = data.rows[0].id
        $log.debug "campaign #{mailCampaign.id} saved"

  getLobData: () ->
    lobData =
      campaign: _getCampaign()
      file: _createLobHtml()
      macros: {}
      recipients: _getLobRecipientData()
      from: _getLobSenderData()



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
          macros: {}
          recipients: _getLobRecipientData()
          from: _getLobSenderData()
