_ = require 'lodash'
{jobQueue} = require '../config/tables'
{crud} = require '../utils/crud/util.crud.service.helpers'

module.exports.taskHistory = crud(jobQueue.taskHistory)
