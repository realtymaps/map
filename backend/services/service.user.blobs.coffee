ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'

class UserBlobsService extends ServiceCrud

UserBlobsService.instance = new UserBlobsService(tables.user.blobs)

module.exports = UserBlobsService
