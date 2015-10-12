logger = require '../config/logger'
auth = require '../utils/util.auth'
rulesService = require '../services/service.dataSourceRules'
ExpressResponse = require '../utils/util.expressResponse'
crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class RuleCrud extends crudHelpers.Crud
  getRules: (req, res, next) =>
    logger.debug "#### getRules()"
    logger.debug "req.params:"
    logger.debug JSON.stringify(req.params)
    @svc.getRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType

  createRules: (req, res, next) =>
    @svc.createRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.body

  putRules: (req, res, next) =>
    @svc.putRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.body

  deleteRules: (req, res, next) =>
    @svc.deleteRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType

  getListRules: (req, res, next) =>
    @svc.getListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list

  createListRules: (req, res, next) =>
    @svc.createListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.body

  putListRules: (req, res, next) =>
    @svc.putListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.body

  deleteListRules: (req, res, next) =>
    @svc.deleteListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list


  getRule: (req, res, next) =>
    @svc.getRule req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering

  updateRule: (req, res, next) =>
    @svc.updateRule req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering, req.body

  deleteRule: (req, res, next) =>
    @svc.deleteRule req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering






module.exports = routeHelpers.mergeHandles new RuleCrud(rulesService),
  getRules:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  createRules:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  putRules:
    methods: ['put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deleteRules:
    methods: ['delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getListRules:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  createListRules:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  putListRules:
    methods: ['put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deleteListRules:
    methods: ['delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]

  getRule:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  updateRule:
    methods: ['patch']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deleteRule:
    methods: ['delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]





# rulesService = require '../services/service.dataSourceRules'
# ExpressResponse = require '../utils/util.expressResponse'
# auth = require '../utils/util.auth'

# module.exports =
#   getRules:
#     method: 'get'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.getRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType
#       .then (result) ->
#         if result
#           next new ExpressResponse result
#         else
#           next new ExpressResponse
#             alert:
#               msg: "Unknown rules #{req.params.dataSourceId}, #{req.params.dataSourceType}, #{req.params.dataListType}"
#             404
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   createRules:
#     method: 'post'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.createRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.body
#       .then (result) ->
#         next new ExpressResponse result
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   putRules:
#     method: 'put'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.putRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.body
#       .then (result) ->
#         next new ExpressResponse(result)
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   deleteRules:
#     method: 'delete'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       mlsNormalizationService.deleteRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType
#       .then (result) ->
#         next new ExpressResponse(result)
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   getListRules:
#     method: 'get'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.getListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list
#       .then (result) ->
#         if result
#           next new ExpressResponse result
#         else
#           next new ExpressResponse
#             alert:
#               msg: "Unknown rules #{req.params.dataSourceId}, #{req.params.dataSourceType}, #{req.params.dataListType}, #{req.params.list}"
#             404
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   createListRules:
#     method: 'post'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.createListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.body
#       .then (result) ->
#         next new ExpressResponse result
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   putListRules:
#     method: 'put'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.putListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.body
#       .then (result) ->
#         next new ExpressResponse(result)
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   deleteListRules:
#     method: 'delete'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.deleteListRules req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list
#       .then (result) ->
#         next new ExpressResponse(result)
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   getRule:
#     method: 'get'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.getRule req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering
#       .then (result) ->
#         if result
#           next new ExpressResponse result
#         else
#           next new ExpressResponse
#             alert:
#               msg: "Unknown rule #{req.params.dataSourceId}, #{req.params.dataSourceType}, #{req.params.dataListType}, #{req.params.ordering}"
#             404
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   updateRule:
#     method: 'patch'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.updateRule req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering, req.body
#       .then (result) ->
#         if result
#           next new ExpressResponse(result)
#         else
#           next new ExpressResponse
#             alert:
#               msg: "Unknown rule #{req.params.dataSourceId}, #{req.params.dataSourceType}, #{req.params.dataListType}, #{req.params.list} #{req.params.ordering}"
#             404
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500

#   deleteRule:
#     method: 'delete'
#     middleware: auth.requireLogin(redirectOnFail: true)
#     handle: (req, res, next) ->
#       rulesService.deleteRule req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering
#       .then (result) ->
#         if result
#           next new ExpressResponse(result)
#         else
#           next new ExpressResponse
#             alert:
#               msg: "Unknown rule #{req.params.dataSourceId}, #{req.params.dataSourceType}, #{req.params.dataListType}, #{req.params.list} #{req.params.ordering}"
#             404
#       .catch (error) ->
#         next new ExpressResponse
#           alert:
#             msg: error.message
#           500
