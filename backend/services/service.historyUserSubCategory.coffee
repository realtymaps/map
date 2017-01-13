EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class HistoryUserSubCrudCategory extends EzCrud

HistoryUserSubCrudCategory.instance = new HistoryUserSubCrudCategory(tables.history.userCategory)

module.exports = HistoryUserSubCrudCategory
