auth = require '../utils/util.auth'
{permission} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(permission),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['add_permission','change_permission']})
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['add_permission','change_permission','delete_permission']})
    ]
