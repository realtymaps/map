# bundleLogger
#   ------------
#   Provides gulp style logs to the bundle method in browserify.js
#
gutil = require('gulp-util')
prettyHrtime = require('pretty-hrtime')
startTime = undefined

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
      console.log 'File', path, 'has been added'

    .on 'change', (path) ->
      console.log 'File', path, 'has been changed'

    .on 'unlink', (path) ->
      console.log 'File', path, 'has been removed'

    .on 'addDir', (path) ->
      console.log 'Directory', path, 'has been added'

    .on 'unlinkDir', (path) ->
      console.log 'Directory', path, 'has been removed'

    .on 'error', (error) ->
      console.log 'Error happened', error

    .on 'ready', ->
      console.log 'Initial scan complete. Ready for changes'

    .on 'raw', (event, path, details) ->
      console.log 'Raw event info:', event, path, details

    watcher

