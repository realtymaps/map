{should, expect}= require('chai')
should()
# sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('util:parcelHelpers')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/util.parcelHelpers.coffee"
dataLoadHelpers = rewire "../../../backend/tasks/util.dataLoadHelpers"
tables = require('../../../backend/config/tables')
countyHelpers = rewire '../../../backend/tasks/util.countyHelpers'
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

    it 'util.countyHelpers finalizeData - call tax_12021 (some fipsCode)', () ->
      subtask = data: subtaskDataToBuild.mergeData

      propTaxMock = new SqlMock 'property', 'tax', result: []
      deletesPropMock = new SqlMock 'deletes', 'property'

      tables =
        property:
          tax: propTaxMock.dbFn()
        deletes:
          property: () -> deletesPropMock

      countyHelpers.__set__ 'tables', tables

      countyHelpers.finalizeData({subtask, id:1, data_source_id: 'county'})

      tableName = "tax_#{fipsCode}"
      propTaxMock.tableName.should.be.eql tableName

      regex = new RegExp(tableName)
      regex.test(propTaxMock.toString()).should.be.ok
