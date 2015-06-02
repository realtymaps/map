mlsConfigService = require '../services/service.mls_config'
ExpressResponse = require '../utils/util.expressResponse'

module.exports =
  getAll: (req, res, next) ->
    mlsConfigService.getAll()
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  getById: (req, res, next) ->
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

  update: (req, res, next) ->
    mlsConfigService.update req.params.id, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  updatePropertyData: (req, res, next) ->
    mlsConfigService.updatePropertyData req.params.id, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  # Privileged
  updateServerInfo: (req, res, next) ->
    mlsConfigService.updateServerInfo req.params.id, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  # Privileged
  create: (req, res, next) ->
    mlsConfigService.create req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  # Privileged
  delete: (req, res, next) ->
    mlsConfigService.delete req.params.id
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500
