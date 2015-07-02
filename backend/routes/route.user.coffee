{user} = require '../services/services.user'
{StreamCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'

class UserCrud extends StreamCrud
  permissions: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.permissions()
        .getAll(req.params.id).stringify().pipe(res)

  groups: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups()
        .getAll(req.params.id).stringify().pipe(res)

  profiles: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.profiles()
        .getAll(req.params.id).stringify().pipe(res)

module.exports = new UserCrud(user)
