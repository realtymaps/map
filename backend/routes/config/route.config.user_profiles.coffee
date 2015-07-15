auth = require '../../utils/util.auth'

#STRICTLY FOR ADMIN, otherwise profiles are used by session
module.exports =
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_useraccountprofile','change_useraccountprofile']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_useraccountprofile','change_useraccountprofile','delete_useraccountprofile']}, logoutOnFail:true)
    ]
