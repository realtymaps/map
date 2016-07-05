{should, expect}= require('chai')
should()
# sinon = require 'sinon'
Promise = require 'bluebird'
logger = require('../../specUtils/logger').spawn('util.mlsHelpers.internals')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/util.mlsHelpers.internals"
SqlMock = require '../../specUtils/sqlMock.coffee'
mlsPhotoUtil = require '../../../backend/utils/util.mls.photos'


describe 'util.mlsHelpers.internals', ->
  beforeEach ->

    listing = new SqlMock('normalized', 'listing')

    @tables =
      property:
        listing: () -> listing

    subject.__set__ 'tables', @tables

describe 'makeInsertPhoto', ->
  it 'cdnPhotoStr defined', ->
    data_source_id = 'data_source_id'
    data_source_uuid = 'uuid'
    listingRow = {data_source_id, data_source_uuid}
    cdnPhotoStr = 'http://cdn.com'
    jsonObjStr = JSON.stringify crap: 'crap'
    imageId = 'imageId'
    photo_id = 'photo_id'

    queryString = subject.makeInsertPhoto {
      listingRow
      cdnPhotoStr
      jsonObjStr
      imageId
      photo_id
      doReturnStr: true
    }

    jsonObjStr = jsonObjStr.replace(/\"/g, "\\\"")
    queryString.should.contain("\"cdn_photo\" = '#{cdnPhotoStr}'")

  it 'cdnPhotoStr undefined', ->
    data_source_id = 'data_source_id'
    data_source_uuid = 'uuid'
    listingRow = {data_source_id, data_source_uuid}
    jsonObjStr = JSON.stringify crap: 'crap'
    imageId = 'imageId'
    photo_id = 'photo_id'

    queryString = subject.makeInsertPhoto {
      listingRow
      jsonObjStr
      imageId
      photo_id
      doReturnStr: true
    }

    jsonObjStr = jsonObjStr.replace(/\"/g, "\\\"")
    queryString.should.not.contain('cdn_photo')

  it 'use a real cdnPhotoStr', ->
    data_source_id = 'data_source_id'
    data_source_uuid = 'uuid'
    listingRow = {data_source_id, data_source_uuid}
    jsonObjStr = JSON.stringify crap: 'crap'
    imageId = 'imageId'
    photo_id = 'photo_id'

    cdnPhotoStrPromise = mlsPhotoUtil.getCndPhotoShard {
      newFileName: 'crap.jpg'
      listingRow
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

      queryString = subject.makeInsertPhoto {
        listingRow
        jsonObjStr
        imageId
        photo_id
        doReturnStr: true
        cdnPhotoStr
      }

      jsonObjStr = jsonObjStr.replace(/\"/g, "\\\"")

      logger.debug queryString

      queryString.should.contain("\"cdn_photo\" = '#{cdnPhotoStr}'")
