crudService = require '../utils/crud/util.crud.service.helpers'
tables = require '../config/tables'
dbs = require '../config/dbs'

db = dbs.get('main')

class MailCrud extends crudService.ThenableCrud
  getAll: (args...) ->
    console.log "\n\n #### MailCrud..."
    super(args...)
    .join()
    .then (data) ->
      console.log "\n\ndata:"
      console.log data

    # console.log Object.keys q
    # q


    # q = super(arguments)
    # q.join(
    #   tables.user.project()
    #   .select(db.raw('name as project_name'))
    # )
    # .then (data) ->
    #   console.log "\n\n #### data:"
    #   console.log data
    #   data
    # q



#instance = new crudService.ThenableCrud(tables.mail.campaign)
instance = new MailCrud(tables.mail.campaign)
module.exports = instance
