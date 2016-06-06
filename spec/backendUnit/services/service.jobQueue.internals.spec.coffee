{should, expect}= require('chai')
should()

jqInternals = require '../../../backend/services/service.jobQueue.internals'


describe "service.jobQueue.internals", () ->

  describe 'buildQueuePaginatedSubtaskDatas', () ->

    it 'should build the correct object', () ->
      datas = jqInternals.buildQueuePaginatedSubtaskDatas {
        totalOrList: ['1']
        maxPage: 1
        mergeData:
          normalSubid: '12021'
      }
      datas.should.be.eql [
        offset: 0
        count: 1
        i: 1
        of: 1
        values: [ '1' ]
        normalSubid: '12021'
      ]

  describe 'buildQueueSubtaskDatas', () ->
    it 'should build the correct object', () ->
      paginatedData = jqInternals.buildQueuePaginatedSubtaskDatas {
        totalOrList: ['1']
        maxPage: 1
        mergeData:
          normalSubid: '12021'
      }
      queueData = jqInternals.buildQueueSubtaskDatas {subtask: {}, manualData: paginatedData}
      queueData.subtaskData.should.be.eql [
        offset: 0
        count: 1
        i: 1
        of: 1
        values: [ '1' ]
        normalSubid: '12021'
      ]
