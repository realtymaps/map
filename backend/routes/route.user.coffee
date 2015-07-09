{user} = require '../services/services.user'
{StreamCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'

###
TODO:
- needs validation (leaving this to who actually is using it)
- needs error handling
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
        self.svc.delete(req.params.permission_id).stringify().pipe(res)
      PUT: () ->
        self.svc.update(req.params.permission_id, req.body).stringify().pipe(res)

  groups: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getAll(user_id: req.params.id)
        .stringify().pipe(res)

      POST: () -> #create
        self.svc.groups.create(req.body, undefined, true).stringify().pipe(res)

  groupsById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.groups.getById(req.params.group_id).stringify().pipe(res)
      POST: () ->
        self.svc.groups.create(req.body, req.params.group_id).stringify().pipe(res)
      DELETE: () ->
        self.svc.groups.delete(req.params.group_id).stringify().pipe(res)
      PUT: () ->
        self.svc.groups.update(req.params.group_id, req.body).stringify().pipe(res)

  profiles: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.profiles.getAll(auth_user_id: req.params.id, true).stringify().pipe(res)

      POST: () -> #create
        self.profiles.svc.create(req.body).stringify().pipe(res)

  profilesById: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.svc.profiles.getById(req.params.profile_id)
        .stringify().pipe(res)
      POST: () ->
        self.svc.profiles.create(req.body, req.params.profile_id).stringify().pipe(res)
      DELETE: () ->
        self.svc.profiles.delete(req.params.profile_id).stringify().pipe(res)
      PUT: () ->
        self.svc.profiles.update(req.params.profile_id, req.body).stringify().pipe(res)


module.exports = new UserCrud(user)
