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
    .orderBy 'rm_inserted_time', 'DESC'

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

  getProperties: (project_id, status, auth_user_id) ->
    if status == 'all' || !status
      status = ['ready', 'sending', 'paid']
    if !_.isArray status
      status = [status]

    tables.mail.campaign()
    .select('recipients', 'id', 'template_type', 'stripe_charge', 'name')
    .where
      project_id: project_id
      auth_user_id: auth_user_id
    .whereIn 'status', status
    .then (campaigns) ->

      propertyIndex = {}

      # Add campaign info to each address
      _.each campaigns, (campaign) ->
        c =
          campaign_id: campaign.id
          campaign_name: campaign.name
          template_type: campaign.template_type

        if campaign.stripe_charge?.created
          c.submitted = moment(campaign.stripe_charge.created, 'X').format()

        _.each campaign.recipients, (r) ->
          propertyIndex[r.rm_property_id] ?= []
          propertyIndex[r.rm_property_id].push _.assign r, c

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
