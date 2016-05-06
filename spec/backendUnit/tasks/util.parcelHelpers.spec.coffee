{should, expect}= require('chai')
should()
# sinon = require 'sinon'
Promise = require 'bluebird'
logger = require('../../specUtils/logger').spawn('util::parcelHelpers')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/util.parcelHelpers.coffee"
dataLoadHelpers = rewire "../../../backend/tasks/util.dataLoadHelpers"
SqlMock = require('../../specUtils/sqlMock')
tables = require('../../../backend/config/tables')

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
