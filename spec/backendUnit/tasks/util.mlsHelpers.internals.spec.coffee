{should, expect}= require('chai')
should()
# sinon = require 'sinon'
# Promise = require 'bluebird'
logger = require('../../specUtils/logger').spawn('util.mlsHelpers.internals')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/util.mlsHelpers.internals"
SqlMock = require '../../specUtils/sqlMock.coffee'
mlsPhotoUtil = require '../../../backend/utils/util.mls.photos'


describe 'util.mlsHelpers.internals', ->
  beforeEach ->

    listing = new SqlMock 'property', 'listing'

    @tables =
      property:
        listing: () -> listing

    subject.__set__ 'tables', @tables

describe 'makeInsertPhoto', ->
  it 'cdnPhotoStr defined', ->
    data_source_id = 'data_source_id'
    data_source_uuid = 'uuid'
    cdnPhotoStr = 'http://cdn.com'
    jsonObjStr = JSON.stringify crap: 'crap'
    imageId = 'imageId'
    photo_id = 'photo_id'

    queryString = subject.makeInsertPhoto {
      data_source_id
      data_source_uuid
      cdnPhotoStr
      jsonObjStr
      imageId
      photo_id
      doReturnStr: true
    }

    jsonObjStr = jsonObjStr.replace(/\"/g, "\\\"")
    queryString.should.be.eql """
      UPDATE listing set
      photos=jsonb_set(photos, '{#{imageId}}', '#{jsonObjStr}', true),cdn_photo = '#{cdnPhotoStr}'
      WHERE
       data_source_id = '#{data_source_id}' AND
       data_source_uuid = '#{data_source_uuid}' AND
       photo_id = '#{photo_id}';
    """

  it 'cdnPhotoStr undefined', ->
    data_source_id = 'data_source_id'
    data_source_uuid = 'uuid'
    jsonObjStr = JSON.stringify crap: 'crap'
    imageId = 'imageId'
    photo_id = 'photo_id'

    queryString = subject.makeInsertPhoto {
      data_source_id
      data_source_uuid
      jsonObjStr
      imageId
      photo_id
      doReturnStr: true
    }

    jsonObjStr = jsonObjStr.replace(/\"/g, "\\\"")
    queryString.should.be.eql """
      UPDATE listing set
      photos=jsonb_set(photos, '{#{imageId}}', '#{jsonObjStr}', true)
      WHERE
       data_source_id = '#{data_source_id}' AND
       data_source_uuid = '#{data_source_uuid}' AND
       photo_id = '#{photo_id}';
    """

  it 'use a real cdnPhotoStr', ->
    data_source_id = 'data_source_id'
    data_source_uuid = 'uuid'
    jsonObjStr = JSON.stringify crap: 'crap'
    imageId = 'imageId'
    photo_id = 'photo_id'

    cdnPhotoStrPromise = mlsPhotoUtil.getCndPhotoShard {
      newFileName: 'crap.jpg'
      data_source_uuid
      data_source_id
    }

    cdnPhotoStrPromise
    .then (cdnPhotoStr) ->

      queryString = subject.makeInsertPhoto {
        data_source_id
        data_source_uuid
        jsonObjStr
        imageId
        photo_id
        doReturnStr: true
        cdnPhotoStr
      }

      jsonObjStr = jsonObjStr.replace(/\"/g, "\\\"")

      logger.debug queryString

      queryString.should.be.eql """
        UPDATE listing set
        photos=jsonb_set(photos, '{#{imageId}}', '#{jsonObjStr}', true),cdn_photo = '#{cdnPhotoStr}'
        WHERE
         data_source_id = '#{data_source_id}' AND
         data_source_uuid = '#{data_source_uuid}' AND
         photo_id = '#{photo_id}';
      """
