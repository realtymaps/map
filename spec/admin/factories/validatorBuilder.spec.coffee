_ = require 'lodash'

describe 'validatorBuilder', ->
  beforeEach ->
    angular.mock.module 'rmapsadminapp'

    inject (validatorBuilder) =>
      @validatorBuilder = validatorBuilder

  it 'should transform fields correctly', ->

    typedFieldTestMap = [
       field: @validatorBuilder.updateRule {"DataType": "Int"}
       transform: 'validators.integer({"nullZero":true})'
      ,
       field: @validatorBuilder.updateRule {"DataType": "Decimal"}
       transform: 'validators.float({"nullZero":true})'
      ,
       field: @validatorBuilder.updateRule {"DataType": "Long"}
       transform: 'validators.float({"nullZero":true})'
      ,
       field: @validatorBuilder.updateRule {"DataType": "Character"}
       transform: 'validators.string({"nullEmpty":true})'
      ,
       field: @validatorBuilder.updateRule {"DataType": "DateTime"}
       transform: 'validators.datetime({})'
      ,
       field: @validatorBuilder.updateRule {"DataType": "Boolean", "config": {"value": false}}
       transform: 'validators.nullify({"value":false})'
     ]

    namedFieldTestMap = [
       field: @validatorBuilder.updateRule {"output": "address"}
       transform: 'validators.address({})'
      ,
       field: @validatorBuilder.updateRule {"output": "status", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.updateRule {"output": "substatus", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.updateRule {"output": "status_display", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
    ]

    expect(obj.field.transform).to.equal obj.transform for obj in typedFieldTestMap
    expect(obj.field.transform).to.equal obj.transform for obj in namedFieldTestMap
