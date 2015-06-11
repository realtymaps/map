{DIGIMAPS} = require '../../../backend/config/config'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.parcels.fetcher.digimaps'
Promise = require 'bluebird'
{StringStream} = require '../../../backend/utils/util.streams'

describe 'service.digimaps', ->
    beforeEach ->
        @subject = svc
        currentDir = null
        @mockFtpClient =
            cwdAsync: (dirName) ->
                currentDir = dirName
                Promise.resolve dirName
            pwdAsync: ->
                Promise.resolve currentDir
            listAsync: sinon.stub().returns Promise.resolve [
                    {name:'Points123.zip'}
                ]
            getAsync: (fileName) -> Promise.try ->
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
