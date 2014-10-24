gulp = require 'gulp'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
clean = require 'gulp-rimraf'
plumber = require 'gulp-plumber'

#end dependencies

conf = configFact(
  output =
    filename: paths.dest.scripts + "/[name].wp.js"
    chunkFilename: paths.dest.scripts + "/[id].wp.js"
  ,
  additionalPlugs = [new HtmlWebpackPlugin template: 'app/html/index.html']
)

# console.log require '../../webpack.conf.coffee'
gulp.task 'build_webpack', ['vendor'], ->
  gulp.src [
    'app/assets/**/*.jpg'
    'app/assets/**/*.png'
    'app/styles/**/*.css'
    'app/styles/**/*.styl'
    'app/html/views/**/*.jade'
    'app/html/views/**/*.html'
    'app/scripts/**/*.coffee'
    'app/scripts/**/*.js'
  ]
  .pipe plumber()
  .pipe(gWebpack conf)
  .pipe(gulp.dest(paths.dest.root))

gulp.task 'clean_webpack', ->
  gulp.src [
    paths.destFull.scripts + "/main.wp.js"
  ]
  .pipe plumber()
  .pipe clean()

# removed dependency on clean_webpack to make sure we're not introducing a race condition with the delete
gulp.task 'webpack', ->
  gulp.start 'build_webpack'
