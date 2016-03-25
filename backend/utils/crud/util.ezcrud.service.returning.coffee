ServiceEzCrud = require './util.ezcrud.service.helpers'
_ = require 'lodash'

module.exports =
  class ReturningServiceEzCrud extends ServiceEzCrud
    constructor: (@dbFn, options = {}) ->
      super @dbFn, options
      @returning = options?.returning || 'id'

    extOpts: (options) ->
      @logger.debug 'returning'
      @logger.debug @returning
      if @returning?
        @logger.debug "extending options w/ returning: #{@returning}"
        _.extend options,
          returning: @returning
      options

    create: (entity, options = {}) ->
      @logger.debug "ReturningServiceEzCrud: create"
      super entity, @extOpts options

    update: (entity, options = {}) ->
      @logger.debug "ReturningServiceEzCrud: update"
      super entity, @extOpts options

    upsert: (entity, options = {}) ->
      @logger.debug "ReturningServiceEzCrud: upsert"
      super entity, @extOpts options
