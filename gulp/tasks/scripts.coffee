require '../../common/extensions/strings'
require './markup'
paths = require '../../common/config/paths'
gulp = require 'gulp'
_ = require 'lodash'
logger = (require '../util/logger').spawn('scripts')
browserify = require('../util/browserify')

browserifyTask = ({app, watch, prod, doSourceMaps}) ->
  prod ?= false
  watch ?= false
  doSourceMaps ?= true

  logger.debug -> {app, watch, prod, doSourceMaps}

  #straight from gulp , https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-with-globs.md
  # gulp expects tasks to return a stream, so we create one here.
  # https://github.com/isaacs/node-glob
  inputGlob = ['js', 'coffee'].map (ext) ->
    [
      paths.frontendCommon.root + 'scripts/**/*.' + ext
      '!' + paths.frontendCommon.root + 'scripts/**/*prod.' + ext
      paths[app].root + 'scripts/**/*.' + ext
      '!' + paths[app].root + 'scripts/**/*prod.' + ext
    ]

  inputGlob = _.flatten inputGlob

  if prod
    inputGlob = _.filter inputGlob, (glob) ->
      !glob.match(/\!/g)

  outputName = app + '.bundle.js'

  browserify({inputGlob, outputName, doSourceMaps, prod, watch})

# Markup tasks must run prior to browserify tasks so that templates can be bundled
# This could be changed if templates are individually required via jade
gulp.task 'browserify', gulp.series 'markup', -> browserifyTask app: 'map'
gulp.task 'browserifyAdmin', gulp.series 'markupAdmin', -> browserifyTask app:'admin'

gulp.task 'browserifyProd', gulp.series 'markup', -> browserifyTask app: 'map', prod: true
gulp.task 'browserifyAdminProd', gulp.series 'markupAdmin', -> browserifyTask app:'admin', prod: true

gulp.task 'browserifyAll', gulp.parallel 'browserify', 'browserifyAdmin'
gulp.task 'browserifyAllProd', gulp.parallel 'browserifyProd', 'browserifyAdminProd'

###
NOTE the watches here are the odd ball of all the gulp watches we have.
They are odd in that browserify builds the script and watches at the same
time. Normally in most things we would be against this. However, due to
browserifies watchify rebuild times are greatly improved without the need
of `gulp.lastRun`.

The reason this is a problem is it requires watching to occur
at times when you don't want to (might trigger watches accidently). The main
thing here is specs can not run until all builds are finished. Therefore specs
now depends on watch.

Therefore in most conditions a watch should only watch period.
###
gulp.task 'browserifyWatch', gulp.series 'markup', 'markupWatch', -> browserifyTask app: 'map', watch: true
gulp.task 'browserifyWatchAdmin', gulp.series 'markupAdmin', 'markupWatchAdmin', -> browserifyTask app: 'admin', watch: true
