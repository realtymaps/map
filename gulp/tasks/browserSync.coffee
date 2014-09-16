backEndConfig = require '../../backend/config/config'

browserSync = require 'browser-sync'
gulp = require 'gulp'
log = require('gulp-util').log

# would be nice to delay browserSync until express is really ready
# however I can not figure this out in node via gulp
# it gets stuck in the loop and express is never started
#http = require 'http'
#Promise = require 'bluebird'
#sleep = require('sleep').sleep
#
## log "Config: %j", backEndConfig
#connect = (resolve = (->), reject = (->)) ->
#  connected = false
#  process.nextTick ->
#    while !connected
#      log 'In next tick'
#      http.get("http://localhost:4000/version", (res) ->
#        log "result: #{res.statusCode}"
#        if res.statusCode == 200
#          connected = true
#          resolve()
#        return
#      ).on "error", (e) ->
#        connected = true
#        console.log "Got error: " + e.message
#        reject()
#        return
#      sleep 1
#
#gulp.task 'check_express', (cb) ->
#  new Promise(connect).then ->
#    cb()

#http://www.browsersync.io/docs/gulp/
#http://www.browsersync.io/docs/options/
gulp.task 'browserSync', ['express'], => # 'check_express'], ->
  setTimeout ->
    unless process.env.PORT
      browserSync.init
        files: ['_public/**/*']
        proxy: "localhost:#{backEndConfig.PORT}"
        port: 3000
        open: false #disable browser auto open
  , 5000
