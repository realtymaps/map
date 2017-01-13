EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class HistoryUserCrud extends EzCrud
  # getAll: (entity, options = {}) ->
  #   @dbFn()
  #   .select("#{tables.historyUserCategory.tableName}.*",
  #     "#{tables.historyUserCategory.tableName}.code as category")
  #   .join(tables.historyUserCategory.tableName,
  #     "#{tables.historyUserCategory.tableName}.id",
  #     "#{tables.historyUser.tableName}.category_id")
  #   .join(tables.historyUserSubCategory.tableName,
  #     "#{tables.historyUserSubCategory.tableName}.id",
  #     "#{tables.historyUser.tableName}.category_id")
  #   super(entity, options)

HistoryUserCrud.instance = new HistoryUserCrud(tables.history.user)

module.exports = HistoryUserCrud
