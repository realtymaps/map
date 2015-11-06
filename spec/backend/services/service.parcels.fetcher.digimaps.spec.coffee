rewire = require 'rewire'
svc = rewire '../../../backend/services/service.parcels.fetcher.digimaps'
Promise = require 'bluebird'
{StringStream} = require '../../../backend/utils/util.streams'

describe 'service.digimaps', ->
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

  it 'getParcelZipFileStream', (done) ->
    @subject.getParcelZipFileStream('/ZIPS/Parcels_123.zip', Promise.resolve @mockFtpClient)
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
