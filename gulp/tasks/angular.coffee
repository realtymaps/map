gulp = require 'gulp'
require './scripts'
require './styles'
require './otherAssets'

#styles and markup are in a series due to some bug in node 4 with gulp-sourcemaps
#https://github.com/floridoo/gulp-sourcemaps/issues/73
gulp.task 'angular', gulp.series 'styles', 'markup', 'browserify'

gulp.task 'angularAdmin', gulp.series 'stylesAdmin', 'markupAdmin', 'browserifyAdmin'

gulp.task 'angularProd', gulp.series 'stylesProd', 'markup', 'browserifyProd'

gulp.task 'angularAdminProd', gulp.series 'stylesAdminProd', 'markupAdmin', 'browserifyAdminProd'

gulp.task 'angularWatch', gulp.parallel 'stylesWatch', 'markupWatch', 'browserifyWatch'

gulp.task 'angularWatchAdmin', gulp.parallel 'stylesWatchAdmin', 'markupWatchAdmin', 'browserifyWatchAdmin'
