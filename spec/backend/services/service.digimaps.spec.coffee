{DIGIMAPS} = require '../../../backend/config/config'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.parcels.digimaps'
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
                Promise.resolve dirName
            listAsync: sinon.stub().returns Promise.resolve [
                    'DMP_DELIVERY_20141011'
                    'DMP_DELIVERY_20150108'
                    'DMP_DELIVERY_20150519'
                    'DMP_DELIVERY_20150208'
                ]
            getAsync: (fileName) -> Promise.try ->
                console.log "currentDir: #{currentDir}"
                if currentDir.indexOf('ZIPS') != -1
                    return new StringStream(fileName)
                return new StringStream('Does not exist!')

    it '_getLatestDir', (done) ->
        _getLatestDir = @subject.__get__('_getLatestDir')
        _getLatestDir(@mockFtpClient, name:'DMP_DELIVERY_')
        .then (val) ->
            expect(val).to.be.eql 'DMP_DELIVERY_20150519'
            done()

    it '_goToLatestDir', (done) ->
        _goToLatestDir = @subject.__get__('_goToLatestDir')
        _goToLatestDir(@mockFtpClient)
        .then (val) ->
            expect(val).to.be.eql 'ZIPS'
            done()

    it 'root', (done) ->
        @subject(123, Promise.resolve @mockFtpClient)
        .then (stream) ->
            str = ''
            stream.on 'data', (buf)->
                str += String(buf)
            stream.on 'end', ->
                expect(str).to.be.eql('Parcels_123.zip')
                done()
        .catch (err) ->
            throw err
            done()
