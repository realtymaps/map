{expect, should} = require("chai")
should()
rewire = require 'rewire'
Promise = require 'bluebird'
priceService = rewire '../../../backend/services/service.prices'
logger = require('../../specUtils/logger').spawn('service:prices')


describe "service.prices", ->

  before () ->
    keystore =
      cache:
        getValue: (key, namespace) ->
          prices =
            bnwPage: 0.95
            bnwExtra: 0.1
            colorPage: 1.15
            colorExtra: 0.2

          Promise.resolve(prices)
        

    priceService.__set__ 'keystore', keystore

  it 'should return correct price for 1 color page', (done) ->
    letter =
      pages: 1
      color: true
      recipientCount: 3
    priceService.getPricePerLetter(letter)
    .then (price) ->
      price.should.be.approximately 1.15, 0.004
      done()

  it 'should return correct price for 3 color pages', (done) ->
    letter =
      pages: 3
      color: true
      recipientCount: 3
    priceService.getPricePerLetter(letter)
    .then (price) ->
      price.should.be.approximately 1.55, 0.004
      done()


  it 'should return correct price for 1 bnw page', (done) ->
    letter =
      pages: 1
      color: false
      recipientCount: 3
    priceService.getPricePerLetter(letter)
    .then (price) ->
      price.should.be.approximately 0.95, 0.004
      done()

  it 'should return correct price for 3 bnw pages', (done) ->
    letter =
      pages: 3
      color: false
      recipientCount: 3
    priceService.getPricePerLetter(letter)
    .then (price) ->
      price.should.be.approximately 1.15, 0.004
      done()

