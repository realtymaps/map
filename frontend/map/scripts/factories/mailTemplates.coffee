###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplateFactory', ($rootScope, $log, $q, $modal, rmapsMailCampaignService,
rmapsPrincipalService, rmapsMailTemplateTypeService, rmapsUsStatesService) ->
  $log = $log.spawn 'mail:mailTemplate'

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


  class MailTemplateFactory
    constructor: () ->
      @campaign = null
      @senderData = null
      @_create()

    _create: (newMail = {}, newSender = {}) ->
      @campaign = _.defaults newMail, campaignDefaults
      @senderData = newSender
      $log.debug () => "Created mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"

    _getLobSenderData: () ->
      # https://lob.com/docs#addresses
      lobSenderData = _.cloneDeep @campaign.sender_info
      lobSenderData.name = "#{lobSenderData.first_name ? ''} #{lobSenderData.last_name ? ''}".trim()
      delete lobSenderData.first_name
      delete lobSenderData.last_name
      lobSenderData

    _getLobRecipientData: () ->
      return null unless @campaign.recipients?.length
      _.map @campaign.recipients, (r) ->
        name: r.name ? "Current Resident"
        address_line1: "#{r.street_address_num ? ''} #{r.street_address_name ? ''}"
        address_line2: r.street_address_unit ? ''
        address_city: r.city ? ''
        address_state: r.state ? ''
        address_zip: r.zip ? ''

    getLobData: () ->
      lobData =
        campaign: @campaign
        file: @createLobHtml()
        macros: {}
        recipients: @_getLobRecipientData()
        from: @_getLobSenderData()

    getSenderData: () ->
      return $q.when @campaign.sender_info if !_.isEmpty @campaign.sender_info
      rmapsPrincipalService.getIdentity()
      .then (identity) =>
        rmapsUsStatesService.getById(identity.user.us_state_id)
        .then (state) =>
          @campaign.auth_user_id = identity.user.id
          @campaign.sender_info =
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

    createPreviewHtml: (content) ->
      # all the small class names added that the editor tools use on the content, like .fontSize12 {font-size: 12px}
      fragStyles = require '../../styles/mailTemplates/template-frags.styl'
      classStyles = require '../../styles/mailTemplates/template-classes.styl'
      previewStyles = "body {background-color: #FFF}"
      """
      <html><head><title>#{@campaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>"
      <style>#{fragStyles}#{classStyles}#{previewStyles}</style></head><body class='letter-body'>#{content}</body></html>
      """

    createLobHtml: () ->
      fragStyles = require '../../styles/mailTemplates/template-frags.styl'
      classStyles = require '../../styles/mailTemplates/template-classes.styl'
      """
      <html><head><title>#{@campaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>"
      <style>#{fragStyles}#{classStyles}</style></head><body class='letter-body'>#{@campaign.content}</body></html>
      """

    setTemplateType: (type) ->
      @campaign.template_type = type
      @campaign.content = rmapsMailTemplateTypeService.getHtml(type)

    getCategory: () ->
      rmapsMailTemplateTypeService.getCategoryFromType(@campaign.template_type)

    isSent: () ->
      @campaign.status == 'sent'

    load: (campaignId) ->
      rmapsMailCampaignService.get id: campaignId
      .then (campaigns) =>
        @campaign = campaigns[0] if campaigns.length
        $log.debug () => "Loaded mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"
        @campaign

    save: () ->
      @getSenderData()
      .then () =>
        toSave = _.pick @campaign, _.keys(campaignDefaults)
        toSave.recipients = JSON.stringify toSave.recipients

        profile = rmapsPrincipalService.getCurrentProfile()
        toSave.project_id = profile.project_id

        op = rmapsMailCampaignService.create(toSave) #upserts if not already created (only if using psql 9.5)
        .then ({data}) =>
          @campaign.id = data.rows[0].id
          $log.debug () => "Saved mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"
