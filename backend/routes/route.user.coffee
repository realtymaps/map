auth = require '../utils/util.auth'
{user} = require '../services/services.user'
EzRouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('route:user')
# coffeelint: enable=check_scope
{mergeHandles} = require '../utils/util.route.helpers'
validation = require '../utils/util.validation'
transforms = require '../utils/transforms/transforms.user'
userInternals = require '../services/service.user.internals'
{parseBase64} = require '../utils/util.image'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
transforms = require '../utils/transforms/transforms.user'


getImage = (req, res, next) ->
  validation.validateAndTransformRequest(req, transforms.imageByUser)
  .then (validReq) ->
    userInternals.getImageByUser(validReq.params.id)
    .then ({blob}) ->
      parsed = parseBase64(blob)
      buf = new Buffer(parsed.data, 'base64')
      res.setHeader('Content-Type', parsed.type)
      res.send(buf)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to PUT company image')

class UserCrud extends EzRouteCrud
  constructor:() ->
    super(arguments...)
    @permissionsCrud = new EzRouteCrud @svc.permissions, {
      rootPOSTTransforms: transforms.permissions.rootPOST
      byIdDELETETransforms: transforms.permissions.byIdDELETE
      getEntity:
        rootPOST: 'body'
    }
    @permissions = @permissionsCrud.root
    @permissionsById = @permissionsCrud.byId

    @groupsCrud = new EzRouteCrud @svc.groups, {
      rootPOSTTransforms: transforms.groups.rootPOST
      byIdDELETETransforms: transforms.groups.byIdDELETE
      getEntity:
        rootPOST: 'body'
    }
    @groups = @groupsCrud.root
    @groupsById = @groupsCrud.byId


module.exports = mergeHandles new UserCrud(user),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user']}, logoutOnFail:true)
    ]

  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]

  permissions:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]

  permissionsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]

  groups:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]

  groupsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]

module.exports.image =
  method: 'get'
  middleware: [auth.requireLogin(redirectOnFail: true)]
  handle: getImage
