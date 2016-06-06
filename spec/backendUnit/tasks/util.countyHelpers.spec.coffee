{should, expect}= require('chai')
should()
# sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('util:parcelHelpers')
rewire = require 'rewire'
countyHelpers = rewire '../../../backend/tasks/util.countyHelpers'
countyHelpersInternals = rewire '../../../backend/tasks/util.countyHelpers.internals'
parcelHelpers = rewire '../../../backend/tasks/util.parcelHelpers'
SqlMock = require '../../specUtils/sqlMock'


describe "util.countyHelpers", () ->

  describe "finalizeData", () ->

    propTaxMock = null

    before ->
      subtask =
        data:
          dataType: "normParcel"
          rawDataType: "parcel"
          normalSubid: '1234'
          rawTableSuffix: '1234'
          subset:
            fips_code: '1234'

      propTaxMock = new SqlMock 'property', 'tax', result: [{rm_property_id: 1}]
      mortgagePropMock = new SqlMock 'property', 'mortgage', result: []
      deedPropMock = new SqlMock 'property', 'deed', result: []
      parcelPropMock = new SqlMock 'property', 'parcel', result: []

      deletesPropMock = new SqlMock 'deletes', 'property', result: []


      tables =
        property:
          tax: propTaxMock.dbFn()
          mortgage: mortgagePropMock.dbFn()
          deed: deedPropMock.dbFn()
          parcel: parcelPropMock.dbFn()
        deletes:
          property: deletesPropMock.dbFn()

      countyHelpersInternals.__set__ 'tables', tables
      countyHelpers.__set__ 'internals', countyHelpersInternals
      parcelHelpers.__set__ 'tables', tables
      countyHelpers.__set__ 'parcelHelpers', parcelHelpers

      countyHelpers.finalizeData({subtask, id:1, data_source_id: 'county'})


    it 'should query table with subid', () ->
      expect(propTaxMock.toString()).to.include('tax_1234')
