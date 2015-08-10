mlsConfigService = require '../services/service.mls_config'
ExpressResponse = require '../utils/util.expressResponse'
auth = require '../utils/util.auth'

module.exports =
  getAll:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getAll()
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  getById:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById req.params.id
      .then (result) ->
        if result
          next new ExpressResponse result
        else
          next new ExpressResponse
            alert:
              msg: "Unknown config #{req.params.id}"
            404
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  update:
    method: 'put'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_mlsconfig']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      mlsConfigService.update req.params.id, req.body
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  updatePropertyData:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_mlsconfig_mainpropertydata']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      mlsConfigService.updatePropertyData req.params.id, req.body
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  # Privileged
  updateServerInfo:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['change_mlsconfig_serverdata']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      mlsConfigService.updateServerInfo req.params.id, req.body
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  # Privileged
  create:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['add_mlsconfig']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      mlsConfigService.create req.body
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  # Privileged
  createById:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['add_mlsconfig']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      mlsConfigService.create req.body, req.params.id
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  # Privileged
  delete:
    method: 'delete'
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['delete_mlsconfig']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      mlsConfigService.delete req.params.id
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500
