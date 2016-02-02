app = require '../app.coffee'
validatorBuilder = require '../../../../common/utils/util.validatorBuilder.coffee'

app.service 'rmapsValidatorBuilderService', () ->
  validatorBuilder
