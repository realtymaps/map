###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailTemplateFactory', ($rootScope, $log, $q, $modal, rmapsMailCampaignService,
rmapsPrincipalService, rmapsMailTemplateTypeService, rmapsUsStatesService, rmapsMainOptions) ->
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
    project_id: null
    options:
      color: false

  class MailTemplateFactory
    constructor: (@campaign = {}) ->
      _.defaults @campaign, campaignDefaults
      @_makeDirty()

    _makeDirty: () ->
      @dirty = true
      @review = {}

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
      "<html><head><title>#{@campaign.name}</title><meta charset='UTF-8'><link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>" +
      "<style>#{fragStyles}#{classStyles}#{extraStyles}</style></head><body class='letter-body'>#{content}</body></html>"

    setTemplateType: (type) ->
      @campaign.template_type = type
      @campaign.content = rmapsMailTemplateTypeService.getMailContent(type)
      if @getCategory() == 'pdf'
        @campaign.aws_key = type
      else
        @campaign.aws_key = null
        @campaign.options.color = false
      @_makeDirty()

    unsetTemplateType: () ->
      @campaign.template_type = ''
      @campaign.content = null
      @campaign.aws_key = null
      @campaign.options.color = false
      @_makeDirty()

    getCategory: () ->
      rmapsMailTemplateTypeService.getCategoryFromType(@campaign.template_type)

    isSubmitted: () ->
      @campaign.status != 'ready'

    _getReview: (serviceMethod) ->
      return if !@campaign.id
      if @reviewPromise
        return @reviewPromise

      @reviewPromise = rmapsMailCampaignService[serviceMethod](@campaign.id)
      .then (review) =>
        _.merge @review, review
        @review = _.assign @review, rmapsMailTemplateTypeService.getMeta()[@campaign.template_type]
      .catch (err) =>
        if err.data?.alert?.msg.indexOf("File length/width is incorrect size.") > -1
          errorMsg = rmapsMainOptions.mail.sizeErrorMsg
        else
          errorMsg = err.data?.alert?.msg
        @review =
          errorMsg: errorMsg

    getReviewDetails: () ->
      @_getReview 'getReviewDetails'

    getQuoteAndPdf: () ->
      @_getReview 'getQuoteAndPdf'

    # get price based on given # of pages
    getPrice: ({pages}) ->
      pricings = rmapsMainOptions.mail.pricing

      price = "N/A"
      if @campaign.options.color
        price = (pricings.colorPage + ((pages-1) * pricings.colorExtra)) * @campaign.recipients.length
      else
        price = (pricings.bnwPage + ((pages-1) * pricings.bnwExtra)) * @campaign.recipients.length

      price

    save: (options) ->
      if !@dirty and !options?.force
        return $q.when @campaign

      @dirty = false
      @reviewPromise = null

      @getSenderData()
      .then () =>
        toSave = _.pick @campaign, _.keys(campaignDefaults)
        toSave.recipients = JSON.stringify toSave.recipients
        toSave.lob_content = @createLobHtml()
        if !toSave.project_id?
          toSave.project_id = rmapsPrincipalService.getCurrentProfile().project_id

        op = rmapsMailCampaignService.create(toSave) #upserts if not already created (only if using psql 9.5)
        .then ({data}) =>
          @campaign.id = data.rows[0].id
          @campaign
