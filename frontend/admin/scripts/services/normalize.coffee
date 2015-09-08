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
    data_source_type: 'mls'
    data_type: 'listing'

  getRules = (mlsId) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').getList()

  moveRule = (mlsId, rule, listFrom, listTo, idx) ->
    Promise.try () ->
      if rule.list != 'unassigned'
        _.pull listFrom.items, rule
        if listFrom.items != listTo.items
          Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(rule.list).one(String(rule.ordering)).remove()
    .then () ->
      rule.list = listTo.list
      if rule.list != 'unassigned'
        listTo.items.splice idx, 0, rule
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
