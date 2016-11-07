{should, expect}= require('chai')
should()
# sinon = require 'sinon'
Promise = require 'bluebird'
logger = require('../../specUtils/logger').spawn('task.default.mls.photo.internals')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/task.default.mls.photo.internals"
SqlMock = require '../../specUtils/sqlMock.coffee'


describe 'task.default.mls.photo.internals', ->

  _getCdnPhotoShard = subject.__get__('_getCdnPhotoShard')

  subject.__set__ 'keystore', cache:
    getValuesMap: -> Promise.try ->
      prodpull1: {"id":"0", "cdn_id": "499053", "url": "prodpull1.realtymapsterllc.netdna-cdn.com"}
      prodpull2: {"id":"1", "cdn_id": "499059", "url": "prodpull2.realtymapsterllc.netdna-cdn.com"}

  # See SqlMock.coffee for explanation of blockToString
  photo = new SqlMock('finalized', 'photo', blockToString: true)

  tableMocks =
    finalized:
      photo: () -> photo

  beforeEach ->
    photo.resetSpies()

  describe 'getCdnPhotoShard', ->

    it 'returns url', (done) ->
      data_source_id = 'id'
      data_source_uuid = 'uuid'
      row = {data_source_id, data_source_uuid}
      newFileName = 'kitchen.jpg'

      _getCdnPhotoShard({
        row
        newFileName
      })
      .then (url) ->
        url.should.equal 'prodpull2.realtymapsterllc.netdna-cdn.com/api/photos/resize?data_source_id=id&data_source_uuid=uuid'
        done()
