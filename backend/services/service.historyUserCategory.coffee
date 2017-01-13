EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class HistoryUserCrudCategory extends EzCrud

HistoryUserCrudCategory.instance = new HistoryUserCrudCategory(tables.history.userCategory)

module.exports = HistoryUserCrudCategory
