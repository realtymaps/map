{taskHistory} = require '../services/service.jobs'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'

module.exports = routeCrud(taskHistory)
