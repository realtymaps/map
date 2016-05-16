{should, expect}= require('chai')
should()
# sinon = require 'sinon'
Promise = require 'bluebird'
logger = require('../../specUtils/logger').spawn('task:digimaps')
rewire = require 'rewire'
subject = rewire "../../../backend/tasks/task.digimaps"
{NoShapeFilesError, UnzipError} = require('shp2jsonx').errors


describe "task.digimaps", () ->

  describe "handle shp2jsonx errors", ->
    it "NoShapeFilesError", () ->
      Promise.try () ->
        throw new NoShapeFilesError 'test'
      .catch NoShapeFilesError, (error) ->
        logger.debug error

    it "UnzipError", () ->
      Promise.try () ->
        throw new UnzipError 'test'
      .catch UnzipError, (error) ->
        logger.debug error
