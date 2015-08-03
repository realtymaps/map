_ = require 'lodash'

describe 'validatorBuilder', ->
  beforeEach ->
    angular.mock.module 'rmapsadminapp'

    inject (validatorBuilder) =>
      @validatorBuilder = validatorBuilder

  it 'should transform fields correctly', ->

    typedFieldTestMap = [
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
     ]

    namedFieldTestMap = [
       field: @validatorBuilder.buildBaseRule {"output": "address"}
       transform: 'validators.address({})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "status", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "substatus", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: @validatorBuilder.buildBaseRule {"output": "status_display", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
    ]

    expect(obj.field.getTransform()).to.equal obj.transform for obj in typedFieldTestMap
    expect(obj.field.getTransform()).to.equal obj.transform for obj in namedFieldTestMap
