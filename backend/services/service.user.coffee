{userData} = require '../config/tables'
{crud} = require '../utils/crud/util.crud.service.helpers'

module.exports = crud(userData.user)
