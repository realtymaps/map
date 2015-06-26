app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNormalizeService', ['Restangular', (Restangular) ->

  mlsConfigAPI = backendRoutes.mls_config.apiBaseMlsConfig

  _formatRule = (rule) ->
    config: rule.config
    transform: rule.transform
    output: rule.output
    input: JSON.stringify(rule.input) # ensure strings are quoted
    required: !!rule.required

  getRules = (mlsId) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').getList()

  moveRule = (mlsId, rule, listFrom, listTo, idx) ->
    _.pull listFrom.items, rule
    listTo.items.splice idx, 0, rule
    if rule.list != 'unassigned'
      Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(rule.list).one(String(rule.ordering)).remove()
    rule.list = listTo.list
    rule.ordering = idx
    if rule.list != 'unassigned'
      createListRules(mlsId, listTo.list, listTo.items)

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
