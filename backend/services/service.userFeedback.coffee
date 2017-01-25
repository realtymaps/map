EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class UserFeedbackCrud extends EzCrud
  # getAll: (entity, options = {}) ->
  #   @dbFn()
  #   .select("#{tables.lookup.userFeedbackCategory.tableName}.*",
  #     "#{tables.lookup.userFeedbackCategory.tableName}.code as category")
  #   .join(tables.lookup.userFeedbackCategory.tableName,
  #     "#{tables.lookup.userFeedbackCategory.tableName}.id",
  #     "#{tables.history.userFeedback.tableName}.category")
  #   .join(tables.lookup.userFeedbackSubcategory.tableName,
  #     "#{tables.userFeedbackSubcategory.tableName}.id",
  #     "#{tables.userFeedback.tableName}.subcategory")
  #   super(entity, options)

UserFeedbackCrud.instance = new UserFeedbackCrud(tables.history.userFeedback)

module.exports = UserFeedbackCrud
