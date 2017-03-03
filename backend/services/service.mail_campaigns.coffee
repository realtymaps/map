ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'
lobService = require './service.lob'
tables = require '../config/tables'
dbs = require '../config/dbs'
_ = require 'lodash'
db = dbs.get('main')
propertySvc = require './service.properties.combined.details'
logger = require('../config/logger').spawn('service:mail_campaigns')
Promise = require 'bluebird'


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
      db.raw("#{tables.mail.pdfUpload.tableName}.filename as filename"),
      db.raw("#{tables.user.project.tableName}.name as project_name"),
      db.raw("#{tables.mail.campaign.tableName}.project_id as project_id")
    )
    .join("#{tables.user.project.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.project_id", "#{tables.user.project.tableName}.id")
    )
    .leftOuterJoin("#{tables.mail.pdfUpload.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.aws_key", "#{tables.mail.pdfUpload.tableName}.aws_key")
    )

    super(entity, query: logger.debugQuery(query))


  # any details for a mail review shall be delivered upon this service call
  getReviewDetails: (user_id, campaign_id) ->
    # flattening a variety of review details & statistics into a single row response
    tables.mail.letters()
    .select(
      # sum of letters that have been sent
      db.raw("SUM(CASE WHEN (status='sent') THEN 1 ELSE 0 END) as sent"),
      () ->
        @select(db.raw('MAX((lob_response::jsonb->\'expected_delivery_date\')::text) as expected_delivery_date'))
        .from("#{tables.mail.letters.tableName}")
        .where {'user_mail_campaign_id': campaign_id, auth_user_id: user_id}
        .whereNotNull("#{tables.mail.letters.tableName}.lob_response")
    )
    .count '*'
    .where {'user_mail_campaign_id': campaign_id, auth_user_id: user_id}
    .then ([letterResults]) ->

      # fresh pdf url and price
      lobService.getPriceQuote user_id, campaign_id
      .then (response) ->

        # 'sent' and 'total' statistics
        return {
          expected_delivery_date: letterResults.expected_delivery_date
          sent: letterResults.sent
          total: letterResults.count
          pdf: response.pdf
          price: response.price
        }

  getProperties: (project_id, auth_user_id) ->

    if !project_id? || !auth_user_id?
      return Promise.resolve([])

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
        letter.lob = {
          id: letter.lob_response.id
          date_created: letter.lob_response.date_created
          rendered: (letter.lob_response.thumbnails.length > 0)
          preview: "//api/getLetterPreview/#{letter.letter_id}/"
        }


        delete letter.lob_response
        letter.recipientType = letter.options?.metadata?.recipientType
        delete letter.options
        propertyIndex[letter.rm_property_id] ?= []
        propertyIndex[letter.rm_property_id].push letter

      tables.user.profile()
      .where({auth_user_id, project_id})
      .then ([profile]) ->
        if !profile? # or should we throw and return Bad Request or Not Found on route?
          return []

        propertySvc.getProperties({
          query:
            rm_property_id: _.keys propertyIndex
          profile
        })
        .then (details) ->
          _.map details, (detail) ->

            # Combined mailing and property info
            _.assign detail,
              mailings: propertyIndex[detail.rm_property_id]
              coordinates: detail.geometry_center.coordinates
              type: detail.geometry_center.type

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
      "#{tables.mail.letters.tableName}.lob_api as lob_api"
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
        'lob_errors',
        'lob_api'
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

      lobService.sendLetter letter, 'test'

      .then (lobResponse) ->
        logger.debug -> "#{JSON.stringify lobResponse, null, 2}"
        tables.mail.letters()
        .update
          lob_response: lobResponse
          status: 'sent'
          retries: letter.retries + 1
        .where
          id: letter.id
        .then () ->
          lobResponse

  sendCampaign: (auth_user_id, campaign_id) ->
    lobService.sendCampaign auth_user_id, campaign_id


instance = new MailService(tables.mail.campaign, {debugNS: "mailService"})
module.exports = instance
