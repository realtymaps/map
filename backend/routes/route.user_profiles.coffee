auth = require '../utils/util.auth'
{profile} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(profile),
  #STRICTLY FOR ADMIN, otherwise profiles are used by session
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
