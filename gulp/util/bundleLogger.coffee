# bundleLogger
#   ------------
#   Provides gulp style logs to the bundle method in browserify.js
#
gutil = require('gulp-util')
prettyHrtime = require('pretty-hrtime')
startTime = undefined
logger = require('../../backend/config/logger').spawn('bundleLogger')

module.exports =
  start: ->
    startTime = process.hrtime()
    gutil.log 'Running', gutil.colors.green('bundle') + '...'

  end: ->
    taskTime = process.hrtime(startTime)
    prettyTime = prettyHrtime(taskTime)
    gutil.log 'Finished', gutil.colors.green('bundle'), 'in', gutil.colors.magenta(prettyTime)

  logEvents: (watcher) ->
    # Useful for debugging file watch issues
    watcher.on 'add', (path) ->
      logger.info 'File', path, 'has been added'

    .on 'change', (path) ->
      logger.info 'File', path, 'has been changed'

    .on 'unlink', (path) ->
      logger.info 'File', path, 'has been removed'

    .on 'addDir', (path) ->
      logger.info 'Directory', path, 'has been added'

    .on 'unlinkDir', (path) ->
      logger.info 'Directory', path, 'has been removed'

    .on 'error', (error) ->
      logger.error 'Error happened', error

    .on 'ready', ->
      logger.info 'Initial scan complete. Ready for changes'

    .on 'raw', (event, path, details) ->
      logger.info 'Raw event info:', event, path, details

    watcher

