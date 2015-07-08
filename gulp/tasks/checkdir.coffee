gulp = require 'gulp'
fs = require 'fs'
{log} = require 'gulp-util'

gulp.task 'prodAssetCheck', (cb) ->
  fs.lstat '_public', (err, stats) ->
    if !err && stats.isDirectory()
      log("Production Assets Exist exiting!")
      process.exit(0)
    cb()
