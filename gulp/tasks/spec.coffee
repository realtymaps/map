gulp = require 'gulp'

require './angular'
require './otherAssets'
require './karma'
require './mocha'
require './protractor'
open = require 'open'

#NOTE if we add protractor it will need to fire up express first with the assets built

gulp.task 'spec', gulp.parallel('commonSpec', 'backendSpec', 'frontendSpec', 'gulpSpec')

gulp.task 'rebuildSpec', gulp.series('otherAssets', 'browserifyAll', 'spec')

gulp.task 'rspec', gulp.series 'rebuildSpec'

#front end coverage
gulp.task 'openCoverage', (done) ->
  open 'http://localhost:8085/coverage/application/index.html', 'Google Chrome', done

gulp.task 'rcoverage', gulp.series 'vendor', 'frontendCoverageSpec', 'openCoverage'
