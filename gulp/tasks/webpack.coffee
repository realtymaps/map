gulp = require 'gulp'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
#end dependencies

conf = configFact(
  output =
    filename: "js/[name].wp.js"
    chunkFilename: "js/[id].wp.js"
  ,
  additionalPlugs = [new HtmlWebpackPlugin template: 'app/html/index.html']
)

# console.log require '../../webpack.conf.coffee'
gulp.task 'webpack', ->
  gulp.src [
    'app/scripts/app.coffee'
    'app/scripts/config.coffee'
    'app/scripts/**/*.coffee'
    'app/scripts/**/*.js'
    'app/styles/*.css'
    'app/styles/**/*.css'
  ]
  .pipe(gWebpack conf)
  .pipe(gulp.dest('_public/'))
