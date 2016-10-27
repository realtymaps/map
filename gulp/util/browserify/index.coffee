globby = require 'globby'
watchify = require 'watchify'
through = require 'through2'
ignore = require 'ignore'
_ = require 'lodash'
logger = (require '../../util/logger').spawn('browserify')
paths = require '../../../common/config/paths'
internals = require './browserify.internals'

module.exports = ({inputGlob, outputName, doSourceMaps, watch}) ->
  times = startTime: ''

  # logger.debug -> "@@@@ inputGlob @@@@"
  # logger.debug -> inputGlob
  # logger.debug -> "@@@@@@@@@@@@@@@@@@@"

  globby(inputGlob)
  .catch (err) ->
    if (err)
      logger.error err.stack
      return through().emit('error', err)
  .then (entries) ->
    config =
      entries: entries
      outputName: outputName
      dest: paths.destFull.scripts
      debug: true

    if watch
      _.extend config, watchify.args

    # This file acts like a .gitignore for excluding files from linter
    lintIgnore = ignore().addIgnoreFile __dirname + '/../../.coffeelintignore'

    bStream = internals.createBStream({config, lintIgnore, watch, doSourceMaps})

    if watch
      internals.handleWatch({bStream, inputGlob, times, outputName, config, entries, doSourceMaps})

    else
      if config.require
        bStream.require config.require
      if config.external
        bStream.external config.external

    # finally push the files through
    internals.bundle({config, entries, bStream, times, outputName, doSourceMaps})
