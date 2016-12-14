app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
Promise = require 'bluebird'
_ = require 'lodash'


app.factory 'rmapsNormalizeFactory', ($log, Restangular) ->

  ruleAPI = backendRoutes.data_source.apiBaseDataSource

  class NormalizeService

    constructor: (@data_source_id, @data_source_type, @data_type) ->
      @endpoint = Restangular.all(ruleAPI).one(@data_source_id).all('dataSourceType').one(@data_source_type).all('dataListType').one(@data_type).all('rules')

    _formatRule: (rule) =>
      config: _.omit rule.config, (v) -> !v? || v == ''
      transform: rule.transform
      output: rule.output
      input: JSON.stringify(rule.input) # ensure strings are quoted
      required: !!rule.required
      data_source_type: @data_source_type
      data_type: @data_type

    getRules: () ->
      @endpoint.getList()

    moveRule: (rule, listFrom, listTo, idx) ->
      Promise.try () =>
        if rule.list != 'unassigned'
          _.pull listFrom.items, rule
          if listFrom.items != listTo.items
            @endpoint.one(rule.list).one(String(rule.ordering)).remove()
      .then () =>
        rule.list = listTo.list
        if rule.list != 'unassigned'
          listTo.items.splice idx, 0, rule
          @createListRules listTo.list, listTo.items
          .then () ->
            _.forEach listTo.items, (item, ordering) -> item.ordering = ordering

    moveUnassigned: (rules, listTo, idx) ->
      return unless rules?.length
      listTo.items.splice idx, 0, rules...
      @createListRules listTo.list, listTo.items
      .then () ->
        _.forEach listTo.items, (item, ordering) ->
          item.ordering = ordering
          item.list = listTo.list

    createListRules: (list, rules) ->
      @endpoint.one(list).customPUT _.map(rules, @_formatRule)

    updateRule: (rule) ->
      if rule.list != 'unassigned'
        formatted = @_formatRule(rule)
        @endpoint.one(rule.list).one(String(rule.ordering)).patch(formatted)
