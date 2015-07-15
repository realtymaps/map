auth = require '../../utils/util.auth'

#STRICTLY FOR ADMIN, otherwise projects are used by session
module.exports =
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_project','change_project']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_project','change_project','delete_project']}, logoutOnFail:true)
    ]
