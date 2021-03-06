{should}= require('chai')
should()
Promise = require 'bluebird'
# logger = require('../../specUtils/logger').spawn('task:util:mls:photo')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/task.default.mls.photo.internals"
SqlMock = require '../../specUtils/sqlMock'


describe 'task.default.mls.photo.internals', ->

  subject.__set__ 'keystore', cache:
    getValuesMap: -> Promise.try ->
      prodpull1: {"id":"0", "cdn_id": "499053", "url": "prodpull1-realtymapsterllc.netdna-ssl.com"}
      prodpull2: {"id":"1", "cdn_id": "499059", "url": "prodpull2-realtymapsterllc.netdna-ssl.com"}

  # See SqlMock.coffee for explanation of blockToString
  photo = new SqlMock('finalized', 'photo', blockToString: true)


  beforeEach ->
    photo.resetSpies()

  describe 'getCdnPhotoShard', ->

    it 'returns url', (done) ->
      data_source_id = 'id'
      data_source_uuid = 'uuid'
      row = {data_source_id, data_source_uuid}
      newFileName = 'kitchen.jpg'

      subject.getCdnPhotoShard({
        row
        newFileName
      })
      .then (url) ->
        url.should.equal 'prodpull2-realtymapsterllc.netdna-ssl.com/api/photos/resize?data_source_id=id&data_source_uuid=uuid'
        done()
