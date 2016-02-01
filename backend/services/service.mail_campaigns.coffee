ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
dbs = require '../config/dbs'

db = dbs.get('main')

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

instance = new MailService(tables.mail.campaign, {debugNS: "mailService"})
module.exports = instance
