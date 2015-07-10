{user} = require '../services/services.user'
{StreamCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'

class UserCrud extends StreamCrud
  permissions: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.permissions.getAll(user_id: req.params.id)
        .stringify().pipe(res)

  permissionsById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.permissions.getById(req.params.permission_id)
        .stringify().pipe(res)

  groups: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getAll(user_id: req.params.id)
        .stringify().pipe(res)

  groupsById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getById(req.params.group_id)
        .stringify().pipe(res)


  profiles: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.profiles()
        .getAll(req.params.id).stringify().pipe(res)
        # .then (models) ->
        #   res.json(models)
module.exports = new UserCrud(user)
