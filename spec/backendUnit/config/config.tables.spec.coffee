{should, expect}= require('chai')
should()

tables = require('../../../backend/config/tables')
dataLoadHelpers = require("../../../backend/tasks/util.dataLoadHelpers")

describe 'config.tables', () ->

  describe 'buildTableName', () ->

    it 'should build correct tableName from subid', () ->
      tables.temp.buildTableName('subidString').should.be.eql 'subidString'
