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
       transform: '[validators.nullify({"value":0}),validators.integer({})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Decimal"}
       transform: '[validators.nullify({"value":0}),validators.float({})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Long"}
       transform: '[validators.nullify({"value":0}),validators.float({})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": "DataType": "Character"}
       transform: '[validators.string({"trim":true}),validators.nullify({"value":""})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": {"DataType": "DateTime", "format": 'asdf'}}
       transform: '[validators.datetime({"format":"asdf","outputFormat":"MMMM Do, YYYY"})]'
      ,
       field: @validatorBuilder.buildDataRule {"config": {"DataType": "Boolean"}}
       transform: '[validators.boolean({"truthyOutput":"yes","falsyOutput":"no"}),validators.nullify({"value":false})]'

       # Base rules
      ,
       field: _buildBaseRule {"output": "rm_property_id"}
       transform: '[validators.rm_property_id({})]'
      ,
       field: _buildBaseRule {"output": "days_on_market_filter"}
       transform: '[validators.days_on_market({})]'
      ,
       field: _buildBaseRule {"output": "address"}
       transform: '[validators.address({})]'
      ,
       field: _buildBaseRule {"output": "discontinued_date"}
       transform: '[validators.datetime({})]'
      ,
       field: _buildBaseRule {"output": "status", "config": {"mapping": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.string({"trim":true}),validators.nullify({"value":""}),validators.map({"unmapped":"pass","map":{"Active":"for sale","Pending":"pending"}})]'
      ,
       field: _buildBaseRule {"output": "status_display", "config": {"mapping": {"Active": "for sale", "Pending": "pending"}}}
       transform: '[validators.string({"trim":true}),validators.nullify({"value":""}),validators.map({"unmapped":"pass","map":{"Active":"for sale","Pending":"pending"}})]'
      ,
       field: _buildBaseRule {"output": "acres"}
       transform: '[validators.nullify({"value":0}),validators.lotArea({})]'
      ,
       field: _buildBaseRule {"output": "parcel_id"}
       transform: '[validators.string({"stripFormatting":true,"trim":true}),validators.nullify({"value":""})]'
    ]
    expect(obj.field.getTransformString()).to.equal obj.transform for obj in rules
