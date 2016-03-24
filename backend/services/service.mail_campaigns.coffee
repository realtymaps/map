ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'
lobService = require './service.lob'
tables = require '../config/tables'
dbs = require '../config/dbs'
_ = require 'lodash'
moment = require 'moment'
db = dbs.get('main')
propertySvc = require './service.properties.details'
logger = require('../config/logger').spawn('route:mail_campaigns')
lobSvc = require './service.lob'
LobErrors = require '../utils/errors/util.errors.lob'

class MailService extends ServiceCrud
  getAll: (entity = {}) ->
    # resolve fields of ambiguity in entity string
    if 'auth_user_id' of entity
      entity["#{tables.mail.campaign.tableName}.auth_user_id"] = entity.auth_user_id
      delete entity.auth_user_id
    if 'id' of entity
      entity["#{tables.mail.campaign.tableName}.id"] = entity.id
      delete entity.id
    if 'project_id' of entity
      entity["#{tables.mail.campaign.tableName}.project_id"] = entity.project_id
      delete entity.project_id

    query = @dbFn().select(
      "#{tables.mail.campaign.tableName}.*",
      db.raw("#{tables.user.project.tableName}.name as project_name"),
      db.raw("#{tables.mail.campaign.tableName}.project_id as project_id")
    )
    .join("#{tables.user.project.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.project_id", "#{tables.user.project.tableName}.id")
    )
    .orderBy 'rm_inserted_time', 'DESC'

    super(entity, query: query)

  # any details for a mail review shall be delivered upon this service call
  getReviewDetails: (user_id, campaign_id) ->


    # flattening a variety of review details & statistics into a single row response
    tables.mail.letters()
    .select(
      # sum of letters that have been sent
      db.raw("SUM(CASE WHEN (status='sent') THEN 1 ELSE 0 END) as sent"),

      # sample response from a letter to extract details, such as url
      db.raw("(select lob_response from user_mail_letters where lob_response::text is not NULL and user_mail_campaign_id = #{campaign_id} limit 1)"),

      # stripe_charge from campaign to extract details, such as amount charged
      db.raw("(select stripe_charge from user_mail_campaigns where user_mail_campaigns.stripe_charge::text is not NULL and user_mail_campaigns.id = #{campaign_id} limit 1)")
    )
    .count '*'
    .where {'user_mail_campaign_id': campaign_id}
    .then ([letterResults]) ->
      query = null

      # if it looks like lob has sent some letters...
      if letterResults?.lob_response? and letterResults?.stripe_charge?
        query = lobService.getDetails letterResults.lob_response.id
        .then ({url}) ->
          pdf: url
          price: letterResults.stripe_charge.amount/100

      # if lob has not sent any letters for this campaign...
      else
        query = lobService.getPriceQuote user_id, campaign_id
        .then ({pdf,price}) ->
          pdf: pdf
          price: price

      query.then (response) ->
        # 'sent' and 'total' statistics
        details =
          sent: letterResults.sent
          total: letterResults.count
          pdf: response.pdf
          price: response.price
        details


  getProperties: (project_id, auth_user_id) ->
    tables.mail.campaign().select([
      "#{tables.mail.campaign.tableName}.id as campaign_id"
      "#{tables.mail.campaign.tableName}.name as campaign_name"
      "#{tables.mail.campaign.tableName}.template_type as template_type"
      "#{tables.mail.letters.tableName}.id as letter_id"
      "#{tables.mail.letters.tableName}.lob_response as lob_response"
      "#{tables.mail.letters.tableName}.rm_property_id as rm_property_id"
      "#{tables.mail.letters.tableName}.options as options"
    ])
    .join("#{tables.mail.letters.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.id", "#{tables.mail.letters.tableName}.user_mail_campaign_id")
    )
    .where
      "#{tables.mail.campaign.tableName}.project_id": project_id
      "#{tables.mail.campaign.tableName}.auth_user_id": auth_user_id
    .whereNotNull "#{tables.mail.letters.tableName}.lob_response"

    .then (letters) ->

      propertyIndex = {}

      _.each letters, (letter) ->
        letter.lob = _.pick letter.lob_response, ['id', 'date_created', 'url', 'thumbnails']
        delete letter.lob_response
        letter.recipientType = letter.options?.metadata?.recipientType
        delete letter.options
        propertyIndex[letter.rm_property_id] ?= []
        propertyIndex[letter.rm_property_id].push letter

      propertySvc.getDetails rm_property_id: _.keys propertyIndex
      .then (details) ->
        _.map details, (detail) ->

          # Combined mailing and property info
          _.assign detail,
            mailings: propertyIndex[detail.rm_property_id]
            coordinates: detail.geom_point_json.coordinates
            type: detail.geom_point_json.type

  getLetters: (auth_user_id) ->
    tables.mail.campaign().select([
      "#{tables.mail.campaign.tableName}.id as campaign_id"
      "#{tables.mail.campaign.tableName}.name as campaign_name"
      "#{tables.mail.campaign.tableName}.template_type as template_type"
      "#{tables.mail.letters.tableName}.id as id"
      "#{tables.mail.letters.tableName}.address_to as to"
      "#{tables.mail.letters.tableName}.address_from as from"
      "#{tables.mail.letters.tableName}.rm_property_id as rm_property_id"
      "#{tables.mail.letters.tableName}.status as status"
      "#{tables.mail.letters.tableName}.options as options"
    ])
    .join("#{tables.mail.letters.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.id", "#{tables.mail.letters.tableName}.user_mail_campaign_id")
    )
    .where
      "#{tables.mail.campaign.tableName}.auth_user_id": auth_user_id
      "#{tables.mail.campaign.tableName}.status": "sending"

  testLetter: (letter_id, auth_user_id) ->
    tables.mail.letters()
    .select(
      [
        'id'
        'address_to'
        'address_from'
        'file'
        'options'
        'retries',
        'lob_errors'
        'status'
      ]
    )
    .where(
      'id': letter_id
      'auth_user_id': auth_user_id
    )

    .then ([letter]) ->
      if !letter
        throw new PartiallyHandledError("Letter #{letter_id} not found")
      if !(letter.status == "ready" || letter.status == "error-transient")
        throw new PartiallyHandledError("Letter #{letter_id} must be ready or have only transient error status")

      lobSvc.createLetterTest letter

      .then (lobResponse) ->
        logger.debug -> "#{JSON.stringify lobResponse, null, 2}"
        tables.mail.letters()
        .update
          lob_response: lobResponse
          status: 'sent'
          retries: letter.retries + 1
        .where
          id: letter.id

        lobResponse

instance = new MailService(tables.mail.campaign, {debugNS: "mailService"})
module.exports = instance
