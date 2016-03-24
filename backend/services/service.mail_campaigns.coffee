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
