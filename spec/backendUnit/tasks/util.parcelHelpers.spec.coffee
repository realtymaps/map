{should, expect}= require('chai')
should()
# sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('util:parcelHelpers')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/util.parcelHelpers.coffee"
dataLoadHelpers = rewire "../../../backend/tasks/util.dataLoadHelpers"
tables = require('../../../backend/config/tables')

jqInternals = require '../../../backend/services/service.jobQueue.internals'

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
      subtaskDataToBuild.mergeData.should.be.eql normalSubId: fipsCode

    it 'getFinalizeSubtaskData -> buildQueuePaginatedSubtaskDatas', () ->
      datas = jqInternals.buildQueuePaginatedSubtaskDatas subtaskDataToBuild
      datas.should.be.eql [
        offset: 0
        count: 1
        i: 1
        of: 1
        values: [ '1' ]
        normalSubId: '12021'
      ]
