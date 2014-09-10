basePath = require '../basePath'
sinon = require 'sinon'

userService = require "#{basePath}/services/service.user"
permissionsService = require "#{basePath}/services/service.permissions"



auth = require "#{basePath}/config/auth"



describe 'config/auth'.ourNs().ourNs('Backend'), ->

  describe 'requireLogin', ->
    resultBase = (done, expected, call) ->
      call.should.equal(expected)
      done()
    resultcb = null
    res =
      redirect: () ->
        resultcb("redirect")
      status: () ->
        send: () ->
          resultcb("send")
    next = () ->
      resultcb("next")
      
    it 'should call next() if req.user is set', (done) ->
      requireLogin = auth.requireLogin()
      req = {user:true}
      resultcb = resultBase.bind(null, done, "next")
      requireLogin req, res, next
      
    it 'should call res.redirect if req.user is not set and redirectOnFail is set truthy', (done) ->
      requireLogin = auth.requireLogin(redirectOnFail: true)
      req = {}
      resultcb = resultBase.bind(null, done, "redirect")
      requireLogin req, res, next
      
    it 'should call res.send if req.user is not set and redirectOnFail is not set', (done) ->
      requireLogin = auth.requireLogin()
      req = {}
      resultcb = resultBase.bind(null, done, "send")
      requireLogin req, res, next
      
    it 'should call res.send if req.user is not set and redirectOnFail is set falsy', (done) ->
      requireLogin = auth.requireLogin(redirectOnFail: false)
      req = {}
      resultcb = resultBase.bind(null, done, "send")
      requireLogin req, res, next
