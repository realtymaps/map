{should, expect}= require('chai')
should()
# sinon = require 'sinon'
Promise = require 'bluebird'
logger = require('../../specUtils/logger').spawn('task.default.mls.photo.internals')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/task.default.mls.photo.internals"
SqlMock = require '../../specUtils/sqlMock.coffee'


describe 'task.default.mls.photo.internals', ->

  makeUpdatePhoto = subject.__get__('_makeUpdatePhoto')
  getCdnPhotoShard = subject.__get__('_getCdnPhotoShard')

  # See SqlMock.coffee for explanation of blockToString
  photo = new SqlMock('finalized', 'photo', blockToString: true)

  tableMocks =
    finalized:
      photo: () -> photo

  beforeEach ->
    photo.resetSpies()

  describe 'makeUpdatePhoto', ->

    it 'cdnPhotoStr defined', (done) ->
      data_source_id = 'data_source_id'
      data_source_uuid = 'uuid'
      row = {data_source_id, data_source_uuid}
      cdnPhotoStr = 'http://cdn.com'
      jsonObjStr = JSON.stringify crap: 'crap'
      imageId = 'imageId'
      photo_id = 'photo_id'

      query = makeUpdatePhoto {
        row
        cdnPhotoStr
        jsonObjStr
        imageId
        photo_id
        table: tableMocks.finalized.photo
      }

      tableMocks.finalized.photo().whereSpy.callCount.should.equal 1
      tableMocks.finalized.photo().whereSpy.args[0][0].should.deep.equal row

      tableMocks.finalized.photo().rawSpy.callCount.should.equal 1
      tableMocks.finalized.photo().rawSpy.args[0][0].should.equal("jsonb_set(photos, '{#{imageId}}', ?, true)")
      tableMocks.finalized.photo().rawSpy.args[0][1].should.equal(jsonObjStr)

      tableMocks.finalized.photo().updateSpy.callCount.should.equal 1
      tableMocks.finalized.photo().updateSpy.args[0][0].photos.should.be.ok
      tableMocks.finalized.photo().updateSpy.args[0][0].cdn_photo.should.equal(cdnPhotoStr)

      done()

    it 'cdnPhotoStr undefined', (done) ->
      data_source_id = 'data_source_id'
      data_source_uuid = 'uuid'
      row = {data_source_id, data_source_uuid}
      jsonObjStr = JSON.stringify crap: 'crap'
      imageId = 'imageId'
      photo_id = 'photo_id'

      queryString = makeUpdatePhoto {
        row
        jsonObjStr
        imageId
        photo_id
        table: tableMocks.finalized.photo
      }

      expect(tableMocks.finalized.photo().updateSpy.args[0][0].cdn_photo).to.be.undefined

      done()

    it 'use a real cdnPhotoStr', (done) ->
      data_source_id = 'data_source_id'
      data_source_uuid = 'uuid'
      row = {data_source_id, data_source_uuid}
      jsonObjStr = JSON.stringify crap: 'crap'
      imageId = 'imageId'
      photo_id = 'photo_id'

      cdnPhotoStrPromise = getCdnPhotoShard {
        newFileName: 'crap.jpg'
        row
        shardsPromise: Promise.resolve
          one:
            id: 0
            url: 'cdn1.com'
          two:
            id: 1
            url: 'cdn2.com'
      }

      cdnPhotoStrPromise
      .then (cdnPhotoStr) ->

        queryString = makeUpdatePhoto {
          row
          jsonObjStr
          imageId
          photo_id
          cdnPhotoStr
          table: tableMocks.finalized.photo
        }

        tableMocks.finalized.photo().whereSpy.callCount.should.equal 1
        tableMocks.finalized.photo().whereSpy.args[0][0].should.deep.equal row

        tableMocks.finalized.photo().rawSpy.callCount.should.equal 1
        tableMocks.finalized.photo().rawSpy.args[0][0].should.equal("jsonb_set(photos, '{#{imageId}}', ?, true)")
        tableMocks.finalized.photo().rawSpy.args[0][1].should.equal(jsonObjStr)

        tableMocks.finalized.photo().updateSpy.callCount.should.equal 1
        tableMocks.finalized.photo().updateSpy.args[0][0].photos.should.be.ok
        tableMocks.finalized.photo().updateSpy.args[0][0].cdn_photo.should.equal(cdnPhotoStr)

        done()
