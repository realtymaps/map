expect = require('chai').expect
fs = require 'fs'
Promise = require 'bluebird'
fsStat = Promise.promisify(fs.stat, fs)
path = require 'path'

describe 'lock file', () ->

  it 'file should exist', () ->
    basePath = path.join __dirname, '../../'
    fsStat("#{basePath}/yarn.lock")
    .then (stats) ->
      expect(stats.isFile()).to.be.truthy
