expect = require('chai').expect
fs = require 'fs'
Promise = require 'bluebird'
fsStat = Promise.promisify(fs.stat, fs)
path = require 'path'

describe 'shrinkwrap', () ->

  it 'file should exist', () ->
    basePath = path.join __dirname, '../../'
    fsStat("#{basePath}/npm-shrinkwrap.json")
    .then (stats) ->
      expect(stats.isFile()).to.be.truthy
