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

    super(entity, query: query)

  # any details for a mail review shall be delivered upon this service call
  getReviewDetails: (campaign_id) ->
    tables.mail.letters()
    .select 'lob_response'
    .where user_mail_campaign_id: campaign_id
    .whereNotNull 'lob_response'
    .limit 1
    .then ([result]) ->
      # null lob response indicates the tasks in queue have not completed sending any letters yet
      if !result?.lob_response?
        return pdf: null
      lobService.getDetails result.lob_response.id
      .then ({url}) ->
        pdf: url

  getProperties: (project_id, auth_user_id) ->
    query = tables.mail.campaign()
    query = query.select([
      "#{tables.mail.campaign.tableName}.id as campaign_id"
      "#{tables.mail.campaign.tableName}.name as campaign_name"
      "#{tables.mail.campaign.tableName}.template_type as template_type"
      "#{tables.mail.letters.tableName}.id as letter_id"
      "#{tables.mail.letters.tableName}.lob_response as lob_response"
      "#{tables.mail.letters.tableName}.rm_property_id as rm_property_id"
    ])
    .join("#{tables.mail.letters.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.id", "#{tables.mail.letters.tableName}.user_mail_campaign_id")
    )
    .where
      "#{tables.mail.campaign.tableName}.project_id": project_id
      "#{tables.mail.campaign.tableName}.auth_user_id": auth_user_id
    .whereNotNull "#{tables.mail.letters.tableName}.lob_response"

    query
    .then (letters) ->

      propertyIndex = {}

      _.each letters, (letter) ->
        letter.lob = _.pick letter.lob_response, ['id', 'date_created', 'url']
        delete letter.lob_response
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

instance = new MailService(tables.mail.campaign, {debugNS: "mailService"})
module.exports = instance
