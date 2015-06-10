mlsNormalizationService = require '../services/service.mls_normalization'
ExpressResponse = require '../utils/util.expressResponse'

module.exports =
  getMlsRules: (req, res, next) ->
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

  createMlsRules: (req, res, next) ->
    mlsNormalizationService.createRules req.params.mlsId, req.body
    .then (result) ->
      next new ExpressResponse result
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  putMlsRules: (req, res, next) ->
    mlsNormalizationService.putRules req.params.mlsId, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  deleteMlsRules: (req, res, next) ->
    mlsNormalizationService.deleteRules req.params.mlsId
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  getListRules: (req, res, next) ->
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

  createListRules: (req, res, next) ->
    mlsNormalizationService.createListRules req.params.mlsId, req.params.list, req.body
    .then (result) ->
      next new ExpressResponse result
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  putListRules: (req, res, next) ->
    mlsNormalizationService.putListRules req.params.mlsId, req.params.list, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  deleteListRules: (req, res, next) ->
    mlsNormalizationService.deleteListRules req.params.mlsId, req.params.list
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  getRule: (req, res, next) ->
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

  updateRule: (req, res, next) ->
    mlsNormalizationService.updateRule req.params.mlsId, req.params.list, req.params.ordering, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  deleteRule: (req, res, next) ->
    mlsNormalizationService.deleteRule req.params.mlsId, req.params.list, req.params.ordering
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500


