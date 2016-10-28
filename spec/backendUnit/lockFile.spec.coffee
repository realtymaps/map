expect = require('chai').expect
fs = require 'fs'
Promise = require 'bluebird'
fsStat = Promise.promisify(fs.stat, fs)
path = require 'path'
logger = (require '../specUtils/logger').spawn('lockFile')

describe 'lock file', () ->

  it 'file should exist', () ->
    basePath = path.join __dirname, '../../'
    logger.debug basePath
    fsStat("#{basePath}/npm-shrinkwrap.json")
    .then (stats) ->
      logger.debug stats
      expect(stats.isFile()).to.be.truthy
