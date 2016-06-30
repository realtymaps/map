sinon = require 'sinon'
{expect,should} = require("chai")
should()
Promise = require 'bluebird'
rewire = require 'rewire'
pdfService = rewire '../../../backend/services/service.pdf'


describe "service.pdf", ->

  mockValidPopplerDocument =
    pageCount: 2
    getPage: (idx) ->
      idx-- # zero indexing
      pages = [
        isCropped: false
        media_box:
          x1: 0
          x2: 612
          y1: 0
          y2: 792
      ,
        isCropped: false
        media_box:
          x1: 0
          x2: 612
          y1: 0
          y2: 792
      ]
      pages[idx]

  mockInvalidPopplerDocument =
    pageCount: 2
    getPage: (idx) ->
      idx-- # zero indexing
      pages = [
        isCropped: false
        media_box:
          x1: 0
          x2: 620
          y1: 0
          y2: 813
      ,
        isCropped: false
        media_box:
          x1: 0
          x2: 620
          y1: 0
          y2: 813
      ]
      pages[idx]

  it 'should correctly invalidate pdf', (done) ->

    pdfService.__set__ '_getPdf', () -> Promise.try ->
      return mockInvalidPopplerDocument

    pdfService.validateDimensions()
    .then (isValid) ->
      isValid.should.be.false
      done()

  it 'should correctly validate pdf', (done) ->

    pdfService.__set__ '_getPdf', () -> Promise.try ->
      return mockValidPopplerDocument

    pdfService.validateDimensions()
    .then (isValid) ->
      isValid.should.be.true
      done()