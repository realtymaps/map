{userData} = require '../config/tables'
{Crud} = require '../utils/util.crud.helpers.coffee'

module.exports = new Crud(userData.user)
