Promise = require 'bluebird'
gulp = require('gulp')
path = require('path')
logger = require('../util/logger').spawn("protractor")
{spawn} = require('child_process')


getProtractorBinary = (binaryName) ->
  winExt = if /^win/.test(process.platform) then '.cmd' else ''
  pkgPath = require.resolve('protractor')
  protractorDir = path.resolve(path.join(path.dirname(pkgPath), '..', 'bin'))
  return path.join(protractorDir, '/'+binaryName+winExt)

webdriver = (toDo, done) ->
  # commented out stdio to limit the cruft of webdriver output
  spawn(getProtractorBinary('webdriver-manager'), [toDo])#, {
  #   stdio: 'inherit'
  # })
  .once 'close', done
  .once 'error', done

gulp.task 'webdriver:update', (done) ->
  webdriver('update', done)

gulp.task 'protractor',  gulp.series 'webdriver:update', (done) ->
  Promise.join webdriver('start', done), Promise.delay(4000), (webDriverChild) ->

    pChild = spawn('protractor', ['protractor.config.js'])
    .once('close', done)
    .once('error', done)

    # this would be way less complicated protractor sent the correct exit codes when it finished
    # otherwise the child never finishes
    pChild.stdout.on 'data', (data) ->
      process.stdout.write(data)
      data = String(data)
      if /Finished in.*/.test(data)
        logger.debug -> 'detected FINISH'
        webDriverChild.kill('SIGTERM')
        done()
        pChild.kill('SIGTERM')

      if /Process exited with error code.*/.test(data)
        logger.debug -> 'detected ERROR'
        webDriverChild.kill('SIGTERM')
        done(Number(data.match(/\d*/)[0]))
        pChild.kill('SIGTERM')
