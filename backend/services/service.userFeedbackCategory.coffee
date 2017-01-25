EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class UserFeedbackCategoryCrud extends EzCrud

UserFeedbackCategoryCrud.instance = new UserFeedbackCategoryCrud(tables.lookup.userFeedbackCategory)

module.exports = UserFeedbackCategoryCrud
