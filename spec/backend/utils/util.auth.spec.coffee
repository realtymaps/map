Promise = require 'bluebird'

basePath = require '../basePath'

sessionSecurityService = require "#{basePath}/services/service.sessionSecurity"


auth = require "#{basePath}/utils/util.auth"


describe 'utils/auth'.ns().ns('Backend'), ->

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
