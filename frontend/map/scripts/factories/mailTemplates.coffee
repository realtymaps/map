###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplateFactory', ($rootScope, $window, $log, $timeout, $q, $modal, rmapsMailCampaignService,
rmapsPrincipalService, rmapsEventConstants, rmapsMailTemplateTypeService, rmapsUsStatesService) ->
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


  class mailTemplateFactory
    constructor: () ->
      @campaign = null
      @senderData = null
      @_create()

    _create: (newMail = {}, newSender = {}) ->
      @campaign = _.defaults newMail, campaignDefaults
      @senderData = newSender
      $log.debug () => "Created mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"

    _getSenderData: () ->
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
      "<html><head><title>#{mailCampaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>" +
        "<style>#{fragStyles}#{classStyles}#{previewStyles}</style></head><body class='letter-body'>#{content}</body></html>"

    _createLobHtml: () ->
      fragStyles = require '../../styles/mailTemplates/template-frags.styl'
      classStyles = require '../../styles/mailTemplates/template-classes.styl'
      "<html><head><title>#{mailCampaign.name}</title><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>" +
        "<style>#{fragStyles}#{classStyles}</style></head><body class='letter-body'>#{mailCampaign.content}</body></html>"


    load: (campaignId) ->
      rmapsMailCampaignService.get id: campaignId
      .then (campaigns) =>
        @campaign = campaigns[0] if campaigns.length
        $log.debug () => "Loaded mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"
        @campaign

    save: () ->
      @_getSenderData()
      .then () =>
        toSave = _.pick @campaign, _.keys(campaignDefaults)
        $log.debug () => "Saving @campaign:\n#{JSON.stringify(toSave, null, 2)}"
        toSave.recipients = JSON.stringify toSave.recipients

        profile = rmapsPrincipalService.getCurrentProfile()
        toSave.project_id = profile.project_id

        op = rmapsMailCampaignService.create(toSave) #upserts if not already created
        .then ({data}) =>
          @campaign.id = data.rows[0].id
          $log.debug () => "Saved mail campaign:\n#{JSON.stringify(@campaign, null, 2)}"



    # getAll: (query) ->
    #   $http.get @endpoint, cache: false, params: query
    #   .then ({data}) ->
    #     data

    # create: (entity) ->
    #   $http.post @endpoint, entity

    # update: (entity) ->
    #   throw new Error('entity must have id') unless entity.id
    #   $http.put "#{@endpoint}/#{entity.id}", entity
    # remove: (entity) ->
    #   $http.delete "#{@endpoint}/#{entity.id}"
