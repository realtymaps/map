# ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
# tables = require '../config/tables'
# dbs = require '../config/dbs'

# class MailCrud extends ServiceCrud
#   getAll: (query) ->
#     transaction = @dnFn().select(
#       "#{tables.mail.campaign.tableName}.*",
#       db.raw("#{tables.user.project.tableName}.name as project_name"),
#       db.raw("#{tables.mail.campaign.tableName}.project_id as project_id")
#     )
#     .join("#{tables.user.project.tableName}", () ->
#       this.on("#{tables.mail.campaign.tableName}.project_id", "#{tables.user.project.tableName}.id")
#     )
#     .where(query)
#     super(transaction: transaction)


crudService = require '../utils/crud/util.crud.service.helpers'
tables = require '../config/tables'
dbs = require '../config/dbs'

db = dbs.get('main')

class MailCrud extends crudService.ThenableCrud
  getAll: (query = {}, doLogQuery = false) ->
    transaction = @dbFn
    tableName = @dbFn.tableName

    @dbFn = () =>
      ret = transaction().select(
        "#{tables.mail.campaign.tableName}.*",
        db.raw("#{tables.user.project.tableName}.name as project_name"),
        db.raw("#{tables.mail.campaign.tableName}.project_id as project_id")
      )
      .join("#{tables.user.project.tableName}", () ->
        this.on("#{tables.mail.campaign.tableName}.project_id", "#{tables.user.project.tableName}.id")
      )
      .where(query)

      @dbFn = transaction
      ret
    @dbFn.tableName = tableName
    super(query, doLogQuery)

instance = new MailCrud(tables.mail.campaign).init(false,false,false)
module.exports = instance
