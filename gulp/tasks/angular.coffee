gulp = require 'gulp'
require './scripts'
require './styles'
require './otherAssets'

#styles and markup are in a series due to some bug in node 4 with gulp-sourcemaps
#https://github.com/floridoo/gulp-sourcemaps/issues/73
gulp.task 'angular', gulp.parallel 'styles', 'browserify'

gulp.task 'angularAdmin', gulp.parallel 'stylesAdmin', 'browserifyAdmin'

gulp.task 'angularProd', gulp.parallel 'stylesProd', 'browserifyProd'

gulp.task 'angularAdminProd', gulp.parallel 'stylesAdminProd', 'browserifyAdminProd'

gulp.task 'angularWatch', gulp.parallel 'stylesWatch', 'browserifyWatch'

gulp.task 'angularWatchAdmin', gulp.parallel 'stylesWatchAdmin', 'browserifyWatchAdmin'
