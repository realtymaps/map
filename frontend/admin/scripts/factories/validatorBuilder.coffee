app = require '../app.coffee'
validatorBuilder = require '../../../../common/utils/util.validatorBuilder.coffee'

app.service 'validatorBuilder', ($log) ->
  # $log = nemSimpleLogger.spawn("frontend:admin:validatorBuilder")
  # $log.debug "validatorBuilder controller"
  validatorBuilder
