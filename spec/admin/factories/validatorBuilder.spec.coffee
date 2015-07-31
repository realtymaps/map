_ = require 'lodash'

describe 'validatorBuilder', ->
  beforeEach ->
    angular.mock.module 'rmapsadminapp'

    inject (validatorBuilder) =>
      @validatorBuilder = validatorBuilder

  it 'should transform fields correctly', ->

    typedFieldTestMap = [
       field: {"DataType": "Int"}
       transform: 'validators.integer({})'
      ,
       field: {"DataType": "Decimal"}
       transform: 'validators.float({})'
      ,
       field: {"DataType": "Long"}
       transform: 'validators.float({})'
      ,
       field: {"DataType": "Character"}
       transform: 'validators.string({})'
      ,
       field: {"DataType": "DateTime"}
       transform: 'validators.datetime({})'
      ,
       field: {"DataType": "Boolean", "config": {"value": false}}
       transform: 'validators.nullify({"value":false})'
     ]

    namedFieldTestMap = [
       field: {"output": "address"}
       transform: 'validators.address({})'
      ,
       field: {"output": "status", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: {"output": "substatus", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
      ,
       field: {"output": "status_display", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validators.map({"map":{"Active":"for sale","Pending":"pending"},"passUnmapped":true})'
    ]

    expect(@validatorBuilder.getTransform(obj.field)).to.equal obj.transform for obj in typedFieldTestMap
    expect(@validatorBuilder.getTransform(obj.field)).to.equal obj.transform for obj in namedFieldTestMap
