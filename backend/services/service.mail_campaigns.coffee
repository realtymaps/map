crudService = require '../utils/crud/util.crud.service.helpers'
tables = require '../config/tables'

instance = new crudService.ThenableCrud(tables.mail.campaign)

module.exports = instance
