_ = require 'lodash'

describe 'validatorBuilder', ->
  beforeEach ->
    angular.mock.module 'rmapsadminapp'

    inject (validatorBuilder) =>
      @validatorBuilder = validatorBuilder

  it 'should transform fields correctly', ->

    typedFieldTestMap = [
       field: {"DataType": "Int"}
       transform: 'validation.integer({})'
      ,
       field: {"DataType": "Decimal"}
       transform: 'validation.float({})'
      ,
       field: {"DataType": "Long"}
       transform: 'validation.float({})'
      ,
       field: {"DataType": "Character"}
       transform: 'validation.string({})'
      ,
       field: {"DataType": "DateTime"}
       transform: 'validation.datetime({})'
      ,
       field: {"DataType": "Boolean", "config": {"value": false}}
       transform: 'validation.nullify({"value":false})'
     ]

    namedFieldTestMap = [
       field: {"output": "address"}
       transform: 'validation.address({})'
      ,
       field: {"output": "status", "config": {"choices": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validation.choice({"choices":{"Active":"for sale","Pending":"pending"}})'
      ,
       field: {"output": "substatus", "config": {"choices": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validation.choice({"choices":{"Active":"for sale","Pending":"pending"}})'
      ,
       field: {"output": "status_display", "config": {"choices": {"Active": "for sale", "Pending": "pending"}}}
       transform: 'validation.choice({"choices":{"Active":"for sale","Pending":"pending"}})'
    ]

    expect(@validatorBuilder.getTransform(obj.field)).to.equal obj.transform for obj in typedFieldTestMap
    expect(@validatorBuilder.getTransform(obj.field)).to.equal obj.transform for obj in namedFieldTestMap
