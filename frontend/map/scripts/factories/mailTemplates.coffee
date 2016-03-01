###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplateFactory', ($rootScope, $log, $q, $modal, rmapsMailCampaignService,
rmapsPrincipalService, rmapsMailTemplateTypeService, rmapsUsStatesService) ->
  $log = $log.spawn 'mail:mailTemplate'

  campaignDefaults =
    id: null
    auth_user_id: null
    name: 'New Mailing'
    status: 'ready'
    content: null
    template_type: ''
    lob_content: null
    sender_info: null
    recipients: []
    aws_key: null

  class MailTemplateFactory
    constructor: () ->
      @campaign = null
      @senderData = null
      @_create()

    _create: (newMail = {}, newSender = {}) ->
      @campaign = _.defaults newMail, campaignDefaults
      @senderData = newSender

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

    createLobHtml: (content = @campaign.content, extraStyles = "") ->
      fragStyles = (require '../../styles/mailTemplates/template-frags.styl').replace(/\n/g,'')
      classStyles = (require '../../styles/mailTemplates/template-classes.styl').replace(/\n/g,'')
      "<html><head><title>#{@campaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>" +
      "<style>#{fragStyles}#{classStyles}#{extraStyles}</style></head><body class='letter-body'>#{content}</body></html>"

    setTemplateType: (type) ->
      @campaign.template_type = type
      @campaign.content = rmapsMailTemplateTypeService.getHtml(type)

    getCategory: () ->
      rmapsMailTemplateTypeService.getCategoryFromType(@campaign.template_type)

    isSent: () ->
      @campaign.status == 'paid'

    load: (campaignId) ->
      rmapsMailCampaignService.get id: campaignId
      .then (campaigns) =>
        @campaign = campaigns[0] if campaigns.length
        # $log.debug () => "Loaded mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"
        @campaign

    save: () ->
      @getSenderData()
      .then () =>
        toSave = _.pick @campaign, _.keys(campaignDefaults)
        toSave.recipients = JSON.stringify toSave.recipients
        toSave.lob_content = @createLobHtml()

        if profile = rmapsPrincipalService.getCurrentProfile()
          toSave.project_id = profile.project_id

        op = rmapsMailCampaignService.create(toSave) #upserts if not already created (only if using psql 9.5)
        .then ({data}) =>
          @campaign.id = data.rows[0].id
          # $log.debug () => "Saved mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"
          @campaign
