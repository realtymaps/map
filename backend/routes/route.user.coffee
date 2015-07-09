{user} = require '../services/services.user'
{StreamCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'

###
TODO:
- needs validation (leaving this to who actually is using it)
- on all getById's a useful implementation using streaming to reduce an [] to {} for single results
###
class UserCrud extends StreamCrud
  permissions: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.permissions.getAll(user_id: req.params.id).stringify().pipe(res)

      POST: () -> #create
        self.svc.create(req.body).stringify().pipe(res)

  permissionsById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.permissions.getById(req.params.permission_id)
        .stringify().pipe(res)
      POST: () ->
        self.svc.create(req.body, req.params.permission_id).stringify().pipe(res)
      DELETE: () ->
        self.svc.delete(req.body, req.params.permission_id).stringify().pipe(res)
      PUT: () ->
        self.svc.update(req.params.permission_id, req.body).stringify().pipe(res)

  groups: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getAll(user_id: req.params.id)
        .stringify().pipe(res)

      POST: () -> #create
        self.svc.create(req.body, true).stringify().pipe(res)

  groupsById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getById(req.params.group_id).stringify().pipe(res)
      POST: () ->
        self.svc.create(req.body, req.params.group_id).stringify().pipe(res)
      DELETE: () ->
        self.svc.delete(req.body, req.params.group_id).stringify().pipe(res)
      PUT: () ->
        self.svc.update(req.params.group_id, req.body).stringify().pipe(res)

  profiles: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.profiles
        .getAll(auth_user_id: req.params.id, true).stringify().pipe(res)

      POST: () -> #create
        self.svc.create(req.body)

  profilesById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getById(req.params.profile_id)
        .stringify().pipe(res)
      POST: () ->
        self.svc.create(req.body, req.params.profile_id)
      DELETE: () ->
        self.svc.delete(req.body, req.params.profile_id)
      PUT: () ->
        self.svc.update(req.params.profile_id, req.body)


module.exports = new UserCrud(user)
