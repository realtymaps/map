_ = require 'lodash'

describe 'rmapsAdminApp.validatorBuilder', ->
  beforeEach ->
    angular.mock.module 'rmapsAdminApp'

    inject (validatorBuilder) =>
      @validatorBuilder = validatorBuilder

  it 'should transform fields correctly', ->

    rules = [
      # RETS rules
       field: @validatorBuilder.buildRetsRule {"config": "DataType": "Int"}
       transform: '[validators.integer({}),validators.nullify({"value":0})]'
      ,
       field: @validatorBuilder.buildRetsRule {"config": "DataType": "Decimal"}
       transform: '[validators.float({}),validators.nullify({"value":0})]'
      ,
       field: @validatorBuilder.buildRetsRule {"config": "DataType": "Long"}
       transform: '[validators.float({}),validators.nullify({"value":0})]'
      ,
       field: @validatorBuilder.buildRetsRule {"config": "DataType": "Character"}
       transform: '[validators.string({}),validators.nullify({"value":""})]'
      ,
       field: @validatorBuilder.buildRetsRule {"config": "DataType": "DateTime"}
       transform: '[validators.datetime({})]'
      ,
       field: @validatorBuilder.buildRetsRule {"config": {"DataType": "Boolean", "value": false}}
       transform: '[validators.nullify({"value":false})]'

       # Base rules
      ,
       field: @validatorBuilder.buildBaseRule {"output": "rm_property_id"}
       transform: '[validators.rm_property_id({})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "days_on_market"}
       transform: '[validators.days_on_market({})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "address"}
       transform: '[validators.address({})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "discontinued_date"}
       transform: '[validators.datetime({})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "status", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "substatus", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "status_display", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "acres"}
       transform: '[validators.float({})]'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "parcel_id"}
       transform: '[validators.string({"stripFormatting":true})]'
    ]

    expect(obj.field.getTransformString()).to.equal obj.transform for obj in rules
