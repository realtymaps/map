_ = require 'lodash'

describe 'validatorBuilder', ->
  beforeEach ->
    angular.mock.module 'rmapsadminapp'

    inject (validatorBuilder) =>
      @validatorBuilder = validatorBuilder

  it 'should transform fields correctly', ->

    rules = [
      # RETS rules
       field: @validatorBuilder.buildRetsRule {"DataType": "Int"}
       transform: 'validators.integer({"nullZero":true})'
      ,
       field: @validatorBuilder.buildRetsRule {"DataType": "Decimal"}
       transform: 'validators.float({"nullZero":true})'
      ,
       field: @validatorBuilder.buildRetsRule {"DataType": "Long"}
       transform: 'validators.float({"nullZero":true})'
      ,
       field: @validatorBuilder.buildRetsRule {"DataType": "Character"}
       transform: 'validators.string({"nullEmpty":true})'
      ,
       field: @validatorBuilder.buildRetsRule {"DataType": "DateTime"}
       transform: 'validators.datetime({})'
      ,
       field: @validatorBuilder.buildRetsRule {"DataType": "Boolean", "config": {"value": false}}
       transform: 'validators.nullify({"value":false})'

       # Base rules
      ,
       field: @validatorBuilder.buildBaseRule {"output": "rm_property_id"}
       transform: 'validators.rm_property_id({})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "days_on_market"}
       transform: 'validators.pickFirst({criteria: validators.integer()})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "address"}
       transform: 'validators.address({})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "discontinued_date"}
       transform: 'validators.date({})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "status", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "substatus", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "status_display", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "acres"}
       transform: 'validators.float({})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "parcel_id"}
       transform: 'validators.string({"stripFormatting":true})'
    ]

    expect(obj.field.getTransform()).to.equal obj.transform for obj in rules
