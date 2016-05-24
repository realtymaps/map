{should, expect}= require('chai')
should()
# sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('util:parcelHelpers')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/util.parcelHelpers.coffee"
dataLoadHelpers = rewire "../../../backend/tasks/util.dataLoadHelpers"
tables = require('../../../backend/config/tables')
countyHelpers = rewire '../../../backend/tasks/util.countyHelpers'
countyHelpersInternals = rewire '../../../backend/tasks/util.countyHelpers.internals'
parcelHelpers = rewire '../../../backend/tasks/util.parcelHelpers'
jqInternals = require '../../../backend/services/service.jobQueue.internals'
SqlMock = require '../../specUtils/sqlMock'

describe "util.parcelHelpers", () ->

  describe "recordChangeCounts", () ->
    subid = null
    expectedSubid = 'abcde_digimaps_parcel_1234'

    beforeEach () ->
      subid = dataLoadHelpers.buildUniqueSubtaskName
        batch_id: 'abcde'
        task_name: 'digimaps'
        data: subject.getRecordChangeCountsData('1234')

    it 'getRecordChangeCountsData to buildUniqueSubtaskName produces correct raw table name', () ->
      subid.should.be.eql expectedSubid

    it 'builds correct tableName from subid', () ->
      tables.temp.buildTableName(subid).should.be.eql 'raw_' + expectedSubid

  describe "finalizeData", () ->
    subtask = {}
    ids = ['1']
    fipsCode = '12021'
    numRowsToPageFinalize = 1
    subtaskDataToBuild = null

    beforeEach ->
      subtaskDataToBuild = subject.getFinalizeSubtaskData {
        subtask
        ids
        fipsCode
        numRowsToPageFinalize
      }
    # double checking for normalSubId for countyHelpers
    it 'getFinalizeSubtaskData', () ->
      subtaskDataToBuild.totalOrList.should.be.eql ids
      subtaskDataToBuild.maxPage.should.be.eql numRowsToPageFinalize
      subtaskDataToBuild.mergeData.should.be.eql normalSubid: fipsCode

    it 'getFinalizeSubtaskData -> buildQueuePaginatedSubtaskDatas', () ->
      datas = jqInternals.buildQueuePaginatedSubtaskDatas subtaskDataToBuild
      datas.should.be.eql [
        offset: 0
        count: 1
        i: 1
        of: 1
        values: [ '1' ]
        normalSubid: '12021'
      ]

    it 'getFinalizeSubtaskData -> buildQueuePaginatedSubtaskDatas -> buildQueueSubtaskDatas', () ->
      datas = jqInternals.buildQueuePaginatedSubtaskDatas subtaskDataToBuild
      datas.should.be.eql [
        offset: 0
        count: 1
        i: 1
        of: 1
        values: [ '1' ]
        normalSubid: '12021'
      ]

      jqInternals.buildQueueSubtaskDatas {subtask, manualData: datas}
      .subtaskData.should.be.eql [
        offset: 0
        count: 1
        i: 1
        of: 1
        values: [ '1' ]
        normalSubid: '12021'
      ]

    describe "util.countyHelpers finalizeData - call tax_12021 (some fipsCode)", () ->
      propTaxMock = tableName = null

      before ->
        tableName = "tax_#{fipsCode}"
        subtask = data: subtaskDataToBuild.mergeData

        propTaxMock = new SqlMock 'property', 'tax', result: []
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

        countyHelpers.finalizeData({subtask, id:1, data_source_id: 'county', parcelHelpers})


      it 'tableName', () ->
        propTaxMock.tableName.should.be.eql tableName

      it 'query Regex', () ->
        regex = new RegExp(tableName)
        regex.test(propTaxMock.toString()).should.be.ok
