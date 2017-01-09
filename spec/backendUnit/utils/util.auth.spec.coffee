Promise = require 'bluebird'
{basePath} = require '../globalSetup'
sessionSecurityService = require "#{basePath}/services/service.sessionSecurity"
config = require "#{basePath}/config/config"
require("chai").should()

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
    resultBase = (done, expected, call) ->
      call.should.equal(expected)
      done()
    resultcb = null
    res =
      json: () ->
        resultcb("json")
    next = (err) ->
      if err and err.status
        resultcb("error: #{err.status}")
      else
        resultcb("next")

    it 'should call next() if req.user is set', (done) ->
      requireLogin = auth.requireLogin()
      req = {user:true}
      resultcb = resultBase.bind(null, done, "next")
      requireLogin req, res, next

    it 'should call res.json() if req.user is not set and redirectOnFail is set truthy', (done) ->
      requireLogin = auth.requireLogin(redirectOnFail: true)
      req = {}
      resultcb = resultBase.bind(null, done, "json")
      requireLogin req, res, next

    it 'should call next() with an error object if req.user is not set and redirectOnFail is not set', (done) ->
      requireLogin = auth.requireLogin()
      req = {}
      resultcb = resultBase.bind(null, done, "error: 401")
      requireLogin req, res, next

    it 'should call next() with an error object if req.user is not set and redirectOnFail is set falsy', (done) ->
      requireLogin = auth.requireLogin(redirectOnFail: false)
      req = {}
      resultcb = resultBase.bind(null, done, "error: 401")
      requireLogin req, res, next

  describe 'requirePermissions', ->
    resultBase = (done, expected, call) ->
      call.should.equal(expected)
      done()
    resultcb = null
    res =
      json: () ->
        resultcb("json")
    next = (err) ->
      if err and err.status
        resultcb("error: #{err.status}")
      else
        resultcb("next")

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

    it 'should call next() if req.session.permissions contains any key from permissions.any', (done) ->
      requirePermissions = auth.requirePermissions(any: ["perm1", "perm2"])
      req = {session: {permissions: {perm2: true}}, user: {}}
      resultcb = resultBase.bind(null, done, "next")
      requirePermissions req, res, next

    it 'should call next() with an error object if req.session.permissions does not contain any key from permissions.any', (done) ->
      requirePermissions = auth.requirePermissions(any: ["perm1", "perm2"])
      req = {session: {permissions: {perm3: true}}, user: {}}
      resultcb = resultBase.bind(null, done, "error: 401")
      requirePermissions req, res, next

    it 'should call next() with an error object if req.session.permissions does not contain all keys from permissions.all', (done) ->
      requirePermissions = auth.requirePermissions(all: ["perm1", "perm2"])
      req = {session: {permissions: {perm1: true}}, user: {}}
      resultcb = resultBase.bind(null, done, "error: 401")
      requirePermissions req, res, next

    it 'should call next() if req.session.permissions contains all keys from permissions.all', (done) ->
      requirePermissions = auth.requirePermissions(all: ["perm1", "perm2"])
      req = {session: {permissions: {perm1: true, perm2: true}}, user: {}}
      resultcb = resultBase.bind(null, done, "next")
      requirePermissions req, res, next

    it 'should call next() if req.session.permissions contains the permission passed as a singleton', (done) ->
      requirePermissions = auth.requirePermissions("perm1")
      req = {session: {permissions: {perm1: true, perm2: true}}, user: {}}
      resultcb = resultBase.bind(null, done, "next")
      requirePermissions req, res, next

    it 'should call res.json() instead of next(err) if would fail and logoutOnFail is set truthy', (done) ->
      requirePermissions = auth.requirePermissions({all: ["perm1", "perm2"]}, {logoutOnFail: true})
      req = {session: {permissions: {perm1: true}, destroyAsync: () -> Promise.resolve()}, user: {}, query: {}}
      resultcb = resultBase.bind(null, done, "json")
      requirePermissions req, res, next

  describe 'requireProject', ->
    beforeEach ->
      @resultBase = (done, expected, call) ->
        call.should.equal(expected)
        done()
      @resultcb = null
      @res =
        json: () =>
          @resultcb("json")

      @next = (err) =>
        if err and err.status
          @resultcb("error: #{err.status}")
        else
          @resultcb("next")

    it "should return 401 when no project id or session profiles", (done) ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: id: 1
        params: {}
        session: profiles: {}
      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireProject req, @res, @next


    it "should return 401 when no user", (done) ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: null
        params: id: 1
        session: profiles: {}
      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireProject req, @res, @next


    it "should return 401 if no profiles", (done) ->
      requireProject = auth.requireProject(methods: 'get')
      req =
        method: 'GET'
        user: id: 7
        params: id: 1
        session:
          current_profile_id: 1
          profiles: {}

      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireProject req, @res, @next

    it "should return 401 if project_id does not match a profile", (done) ->
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

      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireProject req, @res, @next

    it "should pass with user, profile, and project as expected", (done) ->
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

      @resultcb = @resultBase.bind(null, done, "next")
      requireProject req, @res, @next

  describe 'requireProjectParent', ->
    beforeEach ->
      @resultBase = (done, expected, call) ->
        call.should.equal(expected)
        done()
      @resultcb = null
      @res =
        json: () =>
          @resultcb("json")

      @next = (err) =>
        if err and err.status
          @resultcb("error: #{err.status}")
        else
          @resultcb("next")

    it "should return 401 when not parent of project", (done) ->
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

      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireProjectParent req, @res, @next

    it "should pass when parent_auth_user_id matches user", (done) ->
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

      @resultcb = @resultBase.bind(null, done, "next")
      requireProjectParent req, @res, @next


  describe 'requireProjectEditor', ->
    beforeEach ->
      @resultBase = (done, expected, call) ->
        call.should.equal(expected)
        done()
      @resultcb = null
      @res =
        json: () =>
          @resultcb("json")

      @next = (err) =>
        if err and err.status
          @resultcb("error: #{err.status}")
        else
          @resultcb("next")

    it "should return 401 when not editor of project", (done) ->
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

      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireProjectEditor req, @res, @next

    it "should pass when user can_edit (even if not parent)", (done) ->
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

      @resultcb = @resultBase.bind(null, done, "next")
      requireProjectEditor req, @res, @next


  describe 'requireSubscriber', ->
    beforeEach ->
      @resultBase = (done, expected, call) ->
        call.should.equal(expected)
        done()
      @resultcb = null
      @res =
        json: () =>
          @resultcb("json")

      @next = (err) =>
        if err and err.status
          @resultcb("error: #{err.status}")
        else
          @resultcb("next")

    it "should return 401 when not a subscriber", (done) ->
      requireSubscriber = auth.requireSubscriber(methods: 'get')
      req =
        method: 'GET'
        user:
          id: 7
          stripe_plan_id: config.SUBSCR.PLAN.NONE
        session:
          subscriptionStatus: config.SUBSCR.STATUS.NONE

      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireSubscriber req, @res, @next


    it "should return 401 when subscription expired", (done) ->
      requireSubscriber = auth.requireSubscriber(methods: 'get')
      req =
        method: 'GET'
        user:
          id: 7
          stripe_plan_id: config.SUBSCR.PLAN.PRO
        session:
          subscriptionStatus: config.SUBSCR.PLAN.EXPIRED

      @resultcb = @resultBase.bind(null, done, "error: 401")
      requireSubscriber req, @res, @next

    it "should pass when user has a paid subscription", (done) ->
      requireSubscriber = auth.requireSubscriber(methods: 'get')
      req =
        method: 'GET'
        user:
          id: 7
          stripe_plan_id: config.SUBSCR.PLAN.PRO
        session:
          subscriptionStatus: config.SUBSCR.STATUS.ACTIVE

      @resultcb = @resultBase.bind(null, done, "next")
      requireSubscriber req, @res, @next
