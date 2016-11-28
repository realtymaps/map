Promise = require 'bluebird'
gulp = require('gulp')
path = require('path')
logger = require('../util/logger').spawn("protractor")
{spawn} = require('child_process')
{lineStream} = require '../../backend/utils/util.streams'
terminate = Promise.promisify(require('terminate'))


getProtractorBinary = (binaryName) ->
  winExt = if /^win/.test(process.platform) then '.cmd' else ''
  pkgPath = require.resolve('protractor')
  protractorDir = path.resolve(path.join(path.dirname(pkgPath), '..', 'bin'))
  return path.join(protractorDir, '/'+binaryName+winExt)

webdriver = (toDo, done = () ->) ->
  # commented out stdio to limit the cruft of webdriver output
  spawn(getProtractorBinary('webdriver-manager'), [toDo])
  .once 'close', done
  .once 'error', done

gulp.task 'webdriver:update', (done) ->
  webdriver('update', done)

gulp.task 'protractor',  gulp.series 'webdriver:update', (done) ->
  Promise.join webdriver('start'), Promise.delay(4000), (webDriverChild) ->

    pChild = spawn('protractor', ['protractor.config.js'])
    .once 'close', () ->
      logger.debug -> 'pChild close'
      done()
    .once 'error', (err) ->
      logger.debug -> 'pChild error'
      done(err)

    # This would be way less complicated if protractor sent the correct exit codes when it finished/failed.
    # Right now the chiilds never exit or error out and the stream to gulp hangs.
    #
    # To get around that we sniff stdout and look for completion and errors manually.
    pChild.stdout
    .pipe(lineStream())
    .on 'data', (data) ->
      process.stdout.write(data)
    .on 'line', (line) ->
      if line.startsWith("Finished in")
        logger.debug -> 'detected FINISH'

        pChild.kill('SIGTERM')
        logger.debug -> "webDriver pid: #{webDriverChild.pid}"
        #using terminate because the webDriverChild spawns a java child process
        #and terminate takes care of the child and all its children
        terminate(webDriverChild.pid)
        .then ->
          logger.debug -> 'killed webDriver and pChild'
          done()
        .catch done

      if /Process exited with error code.*/.test(line)
        logger.debug -> 'detected ERROR'

        pChild.kill('SIGTERM')
        #using terminate because the webDriverChild spawns a java child process
        #and terminate takes care of the child and all its children
        terminate(webDriverChild.pid)
        .then ->
          logger.debug -> 'killed webDriver and pChild'
          done(Number(line.match(/\d*/)[0]))
        .catch done
