EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class UserFeedbackSubcategoryCrud extends EzCrud

UserFeedbackSubcategoryCrud.instance = new UserFeedbackSubcategoryCrud(tables.lookup.userFeedbackSubcategory)

module.exports = UserFeedbackSubcategoryCrud
