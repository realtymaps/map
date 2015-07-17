mlsNormalizationService = require '../services/service.mls_normalization'
ExpressResponse = require '../utils/util.expressResponse'
auth = require '../utils/util.auth'

module.exports =
  getMlsRules:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.getRules req.params.mlsId
      .then (result) ->
        if result
          next new ExpressResponse result
        else
          next new ExpressResponse
            alert:
              msg: "Unknown rules #{req.params.mlsId}"
            404
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  createMlsRules:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.createRules req.params.mlsId, req.body
      .then (result) ->
        next new ExpressResponse result
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  putMlsRules:
    method: 'put'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.putRules req.params.mlsId, req.body
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  deleteMlsRules:
    method: 'delete'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.deleteRules req.params.mlsId
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  getListRules:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.getListRules req.params.mlsId, req.params.list
      .then (result) ->
        if result
          next new ExpressResponse result
        else
          next new ExpressResponse
            alert:
              msg: "Unknown rules #{req.params.mlsId} #{req.params.list}"
            404
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  createListRules:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.createListRules req.params.mlsId, req.params.list, req.body
      .then (result) ->
        next new ExpressResponse result
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  putListRules:
    method: 'put'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.putListRules req.params.mlsId, req.params.list, req.body
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  deleteListRules:
    method: 'delete'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.deleteListRules req.params.mlsId, req.params.list
      .then (result) ->
        next new ExpressResponse(result)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  getRule:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.getRule req.params.mlsId, req.params.list, req.params.ordering
      .then (result) ->
        if result
          next new ExpressResponse result
        else
          next new ExpressResponse
            alert:
              msg: "Unknown rule #{req.params.mlsId} #{req.params.list} #{req.params.ordering}"
            404
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  updateRule:
    method: 'patch'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.updateRule req.params.mlsId, req.params.list, req.params.ordering, req.body
      .then (result) ->
        if result
          next new ExpressResponse(result)
        else
          next new ExpressResponse
            alert:
              msg: "Unknown rule #{req.params.mlsId} #{req.params.list} #{req.params.ordering}"
            404
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  deleteRule:
    method: 'delete'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsNormalizationService.deleteRule req.params.mlsId, req.params.list, req.params.ordering
      .then (result) ->
        if result
          next new ExpressResponse(result)
        else
          next new ExpressResponse
            alert:
              msg: "Unknown rule #{req.params.mlsId} #{req.params.list} #{req.params.ordering}"
            404
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500
