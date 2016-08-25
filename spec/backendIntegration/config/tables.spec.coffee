require('chai').should()
tables = require '../../../backend/config/tables'
{basicColumns} = require '../../../backend/utils/util.sql.columns'
userUtils = require '../../../backend/utils/util.user'

describe 'tables', ->

  describe 'validate schema', ->
    describe 'auth', ->
      describe 'user', ->
        userUtils.safeUserFields.forEach (key) ->
          it key, () ->
            tables.auth.user()
            .then (results) ->
              if results?.length
                exists = Object.keys(results[0]).indexOf(key) >= 0
                exists.should.be.ok

  describe 'user', ->
    describe 'company', ->
      basicColumns.company.forEach (key) ->
        it key, () ->
          tables.user.company()
          .then (results) ->
            if results?.length
              exists = Object.keys(results[0]).indexOf(key) >= 0
              exists.should.be.ok
