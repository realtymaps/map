_ = require 'lodash'
{userData} = require('../config/tables')
toInit = _.pick userData, [
  'user'
  'auth_group'
  'auth_user_groups'
  'auth_permission'
  'auth_group_permissions'
  'auth_user_profile'
  'project'
]

{crud} = require '../utils/crud/util.crud.service.helpers'

for key, val of toInit
  module.exports[key] = crud(val)
