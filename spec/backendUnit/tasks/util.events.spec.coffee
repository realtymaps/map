{should, expect}= require('chai')
should()
# sinon = require 'sinon'
Promise = require 'bluebird'
rewire = require 'rewire'
logger = require('../../specUtils/logger').spawn('util:events')
subject = rewire "../../../backend/tasks/util.events"

describe "util.events", () ->

  describe "_propertiesFlatten", ->
    _propertiesFlatten = null
    beforeEach ->
      _propertiesFlatten = subject.__get__ '_propertiesFlatten'

    it 'some rows', ->
      propertiesMap =
        pin:
          1: {ha:1}
          3: {ha:3}
        unPin:
          2: {ha:2}

      rows = _propertiesFlatten(propertiesMap)
      logger.debug rows

      rows.length.should.be.eql 3

  describe "_propertiesReduce", ->
    _propertiesReduce = null
    beforeEach ->
      _propertiesReduce = subject.__get__ '_propertiesReduce'

    it 'cancels out a pin / unPin', ->
      rows = [
        {
          options: rm_property_id: 1
          sub_type: 'pin'
        }
        {
          options: rm_property_id: 1
          sub_type: 'unPin'
        }
      ]
      propertiesMap = _propertiesReduce(rows)
      logger.debug propertiesMap

      Object.keys(propertiesMap.pin).length.should.be.eql 0
      Object.keys(propertiesMap.unPin).length.should.be.eql 0

    it 'cancels out a pin, unPin, pin is 1 pin', ->
      rows = [
        {
          options: rm_property_id: 1
          sub_type: 'pin'
        }
        {
          options: rm_property_id: 1
          sub_type: 'unPin'
        }
        {
          options: rm_property_id: 1
          sub_type: 'pin'
        }
      ]
      propertiesMap = _propertiesReduce(rows)
      logger.debug propertiesMap

      Object.keys(propertiesMap.pin).length.should.be.eql 1
      Object.keys(propertiesMap.unPin).length.should.be.eql 0

    it 'cancels out a unPin, pin, unPin is 1 unPin', ->
      rows = [
        {
          options: rm_property_id: 1
          sub_type: 'unPin'
        }
        {
          options: rm_property_id: 1
          sub_type: 'pin'
        }
        {
          options: rm_property_id: 1
          sub_type: 'unPin'
        }
      ]
      propertiesMap = _propertiesReduce(rows)
      logger.debug propertiesMap

      Object.keys(propertiesMap.pin).length.should.be.eql 0
      Object.keys(propertiesMap.unPin).length.should.be.eql 1

    it 'cancels out a unFavorite, favorite, unFavorite is 1 unFavorite', ->
      rows = [
        {
          options: rm_property_id: 1
          sub_type: 'unFavorite'
        }
        {
          options: rm_property_id: 1
          sub_type: 'favorite'
        }
        {
          options: rm_property_id: 1
          sub_type: 'unFavorite'
        }
      ]
      propertiesMap = _propertiesReduce(rows)
      logger.debug propertiesMap

      Object.keys(propertiesMap.favorite).length.should.be.eql 0
      Object.keys(propertiesMap.unFavorite).length.should.be.eql 1
