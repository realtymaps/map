mlsConfigService = require '../services/service.mls_config'

module.exports =
  getAll: (req, res, next) ->
    mlsConfigList = mlsConfigService.getAll
    res.send new ExpressResponse mlsConfigList

  getById: (req, res, next) ->
    mlsConfig = mlsConfigService.getById req.params.id
    res.send new ExpressResponse mlsConfig

  update: (req, res, next) ->
    mlsConfig = mlsConfigService.update req.params.id req.body
    res.send new ExpressResponse mlsConfig

  create: (req, res, next) ->
    mlsConfig = mlsConfigService.create req.body
    res.send new ExpressResponse mlsConfig

  delete: (req, res, next) ->
    mlsConfig = mlsConfigService.delete req.params.id
    res.send new ExpressResponse mlsConfig
