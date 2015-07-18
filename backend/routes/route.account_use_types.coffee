auth = require '../utils/util.auth'
{account_use_types} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(account_use_types),
  #STRICTLY FOR ADMIN, otherwise profiles are used by session
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
