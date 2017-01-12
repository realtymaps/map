EzCrud =  require '../utils/crud/util.ezcrud.service.helpers'
tables =  require '../config/tables'

class HistoryUserCrud extends EzCrud

HistoryUserCrud.instance = new HistoryUserCrud(tables.history.user)

module.exports = HistoryUserCrud
