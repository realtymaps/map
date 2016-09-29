rewire = require 'rewire'
svc = rewire '../../../backend/services/service.parcels.fetcher.digimaps'
Promise = require 'bluebird'
{StringStream} = require '../../../backend/utils/util.streams'
require("chai").should()
{expect} = require("chai")
sinon = require 'sinon'

describe 'service.parcel.fetcher.digimaps', ->
  beforeEach ->
    @subject = svc
    currentDir = null
    @mockFtpClient =
      cwd: (dirName) ->
        currentDir = dirName
        Promise.resolve dirName
      pwd: ->
        Promise.resolve currentDir
      list: sinon.stub().returns Promise.resolve [
        {name:'Points123.zip'}
        ]
      get: (fileName) -> Promise.try ->
        return new StringStream(fileName)

    svc.__set__ '_ftpClientFactory', () => Promise.resolve @mockFtpClient

  it 'getZipFileStream', (done) ->
    @subject.getZipFileStream('/ZIPS/Parcels_123.zip', creds:'crap')
    .then (stream) ->
      str = ''
      stream.on 'data', (buf)->
        str += String(buf)
      stream.on 'end', ->
        expect(str).to.be.eql('/ZIPS/Parcels_123.zip')
        done()
    .catch (err) ->
      throw err
      done()
