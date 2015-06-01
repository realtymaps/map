mlsConfigService = require '../services/service.mls_config'
ExpressResponse = require '../utils/util.expressResponse'

module.exports =
  getAll: (req, res, next) ->
    mlsConfigService.getAll()
    .then (result) ->
      res.send new ExpressResponse result

  getById: (req, res, next) ->
    mlsConfigService.getById req.params.id
    .then (result) ->
      res.send new ExpressResponse result

  update: (req, res, next) ->
    mlsConfigService.update req.params.id, req.body
    .then (result) ->
      res.send new ExpressResponse result

  create: (req, res, next) ->
    mlsConfigService.create req.body
    .then (result) ->
      res.send new ExpressResponse result

  delete: (req, res, next) ->
    mlsConfigService.delete req.params.id
    .then (result) ->
      res.send new ExpressResponse result
