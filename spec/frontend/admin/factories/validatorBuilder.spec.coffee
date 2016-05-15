_ = require 'lodash'


describe 'rmapsAdminApp.rmapsValidatorBuilderService', ->

  beforeEach ->
    angular.mock.module 'rmapsAdminApp'

    inject (rmapsValidatorBuilderService) =>
      @validatorBuilder = rmapsValidatorBuilderService

  it 'should transform fields correctly', ->
    _buildBaseRule = @validatorBuilder.buildBaseRule('mls','listing')
    rules = [
      # RETS rules
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Int"}
       transform: '[validators.integer({}),validators.nullify({"value":0})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Decimal"}
       transform: '[validators.float({}),validators.nullify({"value":0})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Long"}
       transform: '[validators.float({}),validators.nullify({"value":0})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Character"}
       transform: '[validators.string({}),validators.nullify({"value":""})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": {"DataType": "DateTime", "format": 'asdf'}}
       transform: '[validators.datetime({"format":"asdf"})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": {"DataType": "Boolean"}}
       transform: '[validators.boolean({}),validators.nullify({"value":false})]'

       # Base rules
      ,
       field: _buildBaseRule {"output": "rm_property_id"}
       transform: '[validators.rm_property_id({})]'
      ,
       field: _buildBaseRule {"output": "days_on_market"}
       transform: '[validators.days_on_market({})]'
      ,
       field: _buildBaseRule {"output": "address"}
       transform: '[validators.address({})]'
      ,
       field: _buildBaseRule {"output": "discontinued_date"}
       transform: '[validators.datetime({})]'
      ,
       field: _buildBaseRule {"output": "status", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.map({"map":{"Active":"for sale","Pending":"pending"},"unmapped":"pass"})]'
      ,
       field: _buildBaseRule {"output": "substatus", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.map({"map":{"Active":"for sale","Pending":"pending"},"unmapped":"pass"})]'
      ,
       field: _buildBaseRule {"output": "status_display", "config": {"map": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.map({"map":{"Active":"for sale","Pending":"pending"},"unmapped":"pass"})]'
      ,
       field: _buildBaseRule {"output": "acres"}
       transform: '[validators.float({}),validators.nullify({"value":0})]'
      ,
       field: _buildBaseRule {"output": "parcel_id"}
       transform: '[validators.string({"stripFormatting":true}),validators.nullify({"value":""})]'
    ]

    expect(obj.field.getTransformString()).to.equal obj.transform for obj in rules
