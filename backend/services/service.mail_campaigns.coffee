ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'
lobService = require './service.lob'
tables = require '../config/tables'
dbs = require '../config/dbs'
_ = require 'lodash'
db = dbs.get('main')
propertySvc = require './service.properties.details'
logger = require('../config/logger').spawn('route:mail_campaigns')

class MailService extends ServiceCrud
  getAll: (query = {}) ->
    # resolve fields of ambiguity in query string
    if 'auth_user_id' of query
      query["#{tables.mail.campaign.tableName}.auth_user_id"] = query.auth_user_id
      delete query.auth_user_id
    if 'id' of query
      query["#{tables.mail.campaign.tableName}.id"] = query.id
      delete query.id

    transaction = @dbFn().select(
      "#{tables.mail.campaign.tableName}.*",
      db.raw("#{tables.user.project.tableName}.name as project_name"),
      db.raw("#{tables.mail.campaign.tableName}.project_id as project_id")
    )
    .join("#{tables.user.project.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.project_id", "#{tables.user.project.tableName}.id")
    )
    .where(query)
    super(query, transaction: transaction)

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

  getProperties: (project_id, status, auth_user_id) ->
    if status == 'all' || !status
      status = ['ready', 'sending', 'paid']
    if !_.isArray status
      status = [status]
    tables.mail.campaign()
    .select('recipients')
    .where
      project_id: project_id
      auth_user_id: auth_user_id
    .whereIn 'status', status
    .then (results) ->
      properties = _.flatten(_.pluck(results, 'recipients'))
      propertyIndex = _.indexBy properties, 'rm_property_id'
      propertySvc.getDetails rm_property_id: _.pluck properties, 'rm_property_id'
      .then (details) ->
        _.map details, (detail) ->
          _.assign detail,
            mail: propertyIndex[detail.rm_property_id]
            coordinates: detail.geom_point_json.coordinates
            type: detail.geom_point_json.type

instance = new MailService(tables.mail.campaign, {debugNS: "mailService"})
module.exports = instance
