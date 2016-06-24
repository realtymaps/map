gulp = require 'gulp'
fs = require 'fs'
{log} = require 'gulp-util'
shutdown = require '../../backend/config/shutdown'

gulp.task 'prodAssetCheck', (cb) ->
  fs.lstat '_public', (err, stats) ->
    if !err && stats.isDirectory()
      log 'Production assets exist: exiting to avoid rebuild.'
      shutdown.exit()
    else
      cb()
