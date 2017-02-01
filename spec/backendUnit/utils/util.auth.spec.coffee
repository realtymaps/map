Promise = require 'bluebird'
{basePath} = require '../globalSetup'
sessionSecurityService = require "#{basePath}/services/service.sessionSecurity"
config = require "#{basePath}/config/config"
require("chai").should()
{expectReject, expectResolve} = require '../../specUtils/promiseUtils'
{NeedsLoginError, PermissionsError} = require "#{basePath}/utils/errors/util.errors.userSession"
ExpressResponse = require "#{basePath}/utils/util.expressResponse"

rewire = require 'rewire'
auth = rewire "#{basePath}/utils/util.auth"

auth.__set__ 'logger',
  debug: () ->
  info: () ->
  warn: () ->
  error: () ->


describe 'util.auth', ->

  # mock this call so we don't actually call the db
  sessionSecurityService.deleteSecurities = () -> Promise.resolve()

  describe 'requireLogin', ->
    resJson = false
    res =
      json: () ->
        resJson = true

    beforeEach () ->
      resJson = false

    it 'should resolve if req.user is set', () ->
      requireLogin = auth.requireLogin()
      req = {user:true}
      expectResolve(requireLogin(req, res))
      .then () ->
        resJson.should.be.falsy

    it 'should reject with an ExpressResponse if req.user is not set and redirectOnFail is not set', () ->
      requireLogin = auth.requireLogin()
      req = {}
      expectReject(requireLogin(req, res), (err) -> err instanceof ExpressResponse)

    it 'should reject with a NeedsLoginError if req.user is not set and redirectOnFail is set falsy', () ->
      requireLogin = auth.requireLogin(redirectOnFail: false)
      req = {}
      expectReject(requireLogin(req, res), NeedsLoginError)

  describe 'requirePermissions', ->
    resJson = false
    res =
      json: () ->
        resJson = true

    beforeEach () ->
      resJson = false

    it 'should throw an error if permissions.any and permissions.all are both truthy', ->
      caught = false
      try
        requirePermissions = auth.requirePermissions(any: true, all: true)
      catch
        caught = true
      finally
        caught.should.be.true

    it 'should throw an error if neither permissions.any nor permissions.all is truthy', ->
      caught = false
      try
        requirePermissions = auth.requirePermissions(any: false, all: false)
      catch
        caught = true
      finally
        caught.should.be.true

    it "should throw an error if neither permissions is something other than an object or string", ->
      caught = false
      try
        requirePermissions = auth.requirePermissions(42)
      catch
        caught = true
      finally
        caught.should.be.true

    it 'should resolve if req.session.permissions contains any key from permissions.any', () ->
      requirePermissions = auth.requirePermissions(any: ["perm1", "perm2"])
      req = {session: {permissions: {perm2: true}}, user: {}}
      expectResolve(requirePermissions(req, res))
      .then () ->
        resJson.should.be.false

    it 'should reject with a PermissionsError if req.session.permissions does not contain any key from permissions.any', () ->
      requirePermissions = auth.requirePermissions({any: ["perm1", "perm2"]}, {logoutOnFail: false})
      req = {session: {permissions: {perm3: true}}, user: {}}
      expectReject(requirePermissions(req, res), PermissionsError)

    it 'should reject with a PermissionsError if req.session.permissions does not contain all keys from permissions.all', () ->
      requirePermissions = auth.requirePermissions({all: ["perm1", "perm2"]}, {logoutOnFail: false})
      req = {session: {permissions: {perm1: true}}, user: {}}
      expectReject(requirePermissions(req, res), PermissionsError)

    it 'should resolve if req.session.permissions contains all keys from permissions.all', () ->
      requirePermissions = auth.requirePermissions(all: ["perm1", "perm2"])
      req = {session: {permissions: {perm1: true, perm2: true}}, user: {}}
      expectResolve(requirePermissions(req, res))
      .then () ->
        resJson.should.be.false

    it 'should resolve if req.session.permissions contains the permission passed as a singleton', () ->
      requirePermissions = auth.requirePermissions("perm1")
      req = {session: {permissions: {perm1: true, perm2: true}}, user: {}}
      expectResolve(requirePermissions(req, res))
      .then () ->
        resJson.should.be.false

  describe 'requireProject', ->
    resJson = false
    res =
      json: () ->
        resJson = true

    beforeEach () ->
      resJson = false

    it "should reject with a PermissionsError when no project id or session profiles", () ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: id: 1
        params: {}
        session: profiles: {}
      expectReject(requireProject(req, @res, @next), PermissionsError)


    it "should reject with a PermissionsError when no user", () ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: null
        params: id: 1
        session: profiles: {}
      expectReject(requireProject(req, @res, @next), PermissionsError)


    it "should reject with a PermissionsError if no profiles", () ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: 1
        session:
          current_profile_id: 1
          profiles: {}

      expectReject(requireProject(req, @res, @next), PermissionsError)

    it "should reject with a PermissionsError if project_id does not match a profile", () ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: "1"  # project id
        session:
          current_profile_id: 1
          profiles:
            "1":
              user_id: 7
              project_id: 2  # project id, diff from above
              parent_auth_user_id: null

      expectReject(requireProject(req, @res, @next), PermissionsError)

    it "should pass with user, profile, and project as expected", () ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: "1"  # project id
        session:
          current_profile_id: 1
          profiles:
            "1":
              user_id: 7
              project_id: 1  # project id, same as above
              parent_auth_user_id: null

      expectResolve(requireProject(req, res))
      .then () ->
        resJson.should.be.falsy

  describe 'requireProjectParent', ->
    resJson = false
    res =
      json: () ->
        resJson = true

    beforeEach () ->
      resJson = false

    it "should reject with a PermissionsError when not parent of project", () ->
      requireProjectParent = auth.requireProjectParent(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: "1"
        session:
          current_profile_id: 1
          profiles:
            "1":
              user_id: 7
              project_id: 1
              parent_auth_user_id: 1

      expectReject(requireProjectParent(req, @res, @next), PermissionsError)

    it "should pass when parent_auth_user_id matches user", () ->
      requireProjectParent = auth.requireProjectParent(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: "1"
        session:
          current_profile_id: 1
          profiles:
            "1":
              user_id: 7
              project_id: 1
              parent_auth_user_id: 7

      expectResolve(requireProjectParent(req, res))
      .then () ->
        resJson.should.be.falsy


  describe 'requireProjectEditor', ->
    resJson = false
    res =
      json: () ->
        resJson = true

    beforeEach () ->
      resJson = false

    it "should reject with a PermissionsError when not editor of project", () ->
      requireProjectEditor = auth.requireProjectEditor(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: "1"
        session:
          current_profile_id: 1
          profiles:
            "1":
              can_edit: false
              user_id: 7
              project_id: 1
              parent_auth_user_id: 1

      expectReject(requireProjectEditor(req, @res, @next), PermissionsError)

    it "should pass when user can_edit (even if not parent)", () ->
      requireProjectEditor = auth.requireProjectEditor(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: "1"
        session:
          current_profile_id: 1
          profiles:
            "1":
              can_edit: true
              user_id: 7
              project_id: 1
              parent_auth_user_id: 1

      expectResolve(requireProjectEditor(req, res))
      .then () ->
        resJson.should.be.falsy


  describe 'requireSubscriber', ->
    resJson = false
    res =
      json: () ->
        resJson = true

    beforeEach () ->
      resJson = false

    it "should reject with a PermissionsError when not a subscriber", () ->
      requireSubscriber = auth.requireSubscriber(methods: 'get')
      req =
        method: 'GET'
        user:
          id: 7
          stripe_plan_id: config.SUBSCR.PLAN.NONE
        session:
          subscriptionStatus: config.SUBSCR.STATUS.NONE

      expectReject(requireSubscriber(req, @res, @next), PermissionsError)


    it "should reject with a PermissionsError when subscription expired", () ->
      requireSubscriber = auth.requireSubscriber(methods: 'get')
      req =
        method: 'GET'
        user:
          id: 7
          stripe_plan_id: config.SUBSCR.PLAN.PRO
        session:
          subscriptionStatus: config.SUBSCR.PLAN.EXPIRED

      expectReject(requireSubscriber(req, @res, @next), PermissionsError)

    it "should pass when user has a paid subscription", () ->
      requireSubscriber = auth.requireSubscriber(methods: 'get')
      req =
        method: 'GET'
        user:
          id: 7
          stripe_plan_id: config.SUBSCR.PLAN.PRO
        session:
          subscriptionStatus: config.SUBSCR.STATUS.ACTIVE

      expectResolve(requireSubscriber(req, res))
      .then () ->
        resJson.should.be.falsy
