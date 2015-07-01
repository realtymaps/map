app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
Promise = require 'bluebird'

app.service 'rmapsNormalizeService', ['Restangular', (Restangular) ->

  mlsConfigAPI = backendRoutes.mls_config.apiBase

  _formatRule = (rule) ->
    config: rule.config
    transform: rule.transform
    output: rule.output
    input: JSON.stringify(rule.input) # ensure strings are quoted
    required: !!rule.required

  getRules = (mlsId) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').getList()

  moveRule = (mlsId, rule, listFrom, listTo, idx) ->
    Promise.try () ->
      _.pull listFrom.items, rule
      if rule.list != 'unassigned' && listFrom.items != listTo.items
        Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(rule.list).one(String(rule.ordering)).remove()
    .then () ->
      listTo.items.splice idx, 0, rule
      rule.list = listTo.list
      if rule.list != 'unassigned'
        createListRules(mlsId, listTo.list, listTo.items)
    .then () ->
      _.forEach listTo.items, (item, ordering) -> item.ordering = ordering

  createListRules = (mlsId, list, rules) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(list).customPUT _.map(rules, _formatRule)

  updateRule = (mlsId, rule) ->
    if rule.list != 'unassigned'
      Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(rule.list).one(String(rule.ordering)).patch(_formatRule(rule))

  service =
    getRules: getRules
    moveRule: moveRule
    createListRules: createListRules
    updateRule: updateRule
]
