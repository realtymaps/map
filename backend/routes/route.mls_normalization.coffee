mlsNormalizationService = require '../services/service.mls_normalization'
ExpressResponse = require '../utils/util.expressResponse'

module.exports =
  getRules: (req, res, next) ->
    mlsNormalizationService.getRules req.params.mlsId
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  createRule: (req, res, next) ->
    mlsNormalizationService.createRule req.params.mlsId, req.params.list, req.body
    .then (result) ->
      if result
        next new ExpressResponse result
      else
        next new ExpressResponse
          alert:
            msg: "Unknown MLS #{req.params.id}"
          404
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  updateRule: (req, res, next) ->
    mlsNormalizationService.UpdateRule req.params.id, req.params.list, req.params.ordering, req.body
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  deleteRule: (req, res, next) ->
    mlsNormalizationService.deleteRule req.params.id, req.params.list, req.params.ordering
    .then (result) ->
      next new ExpressResponse(result)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500


