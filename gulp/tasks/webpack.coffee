gulp = require 'gulp'
require './otherAssets'
require './webroot'
require './clean'

gWebpack = require 'webpack-stream'
configFact = require '../../webpack.conf.coffee'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'
fs = require 'fs'
webpack = require 'webpack'

output = paths.destFull.webpack.map
outputAdmin = paths.destFull.webpack.admin
# webpack confs per each environment & app
conf = configFact output

prodConf = configFact _.omit(output, 'publicPath'),
  new webpack.optimize.UglifyJsPlugin {
    mangle: false,
    compress: {
      warnings: false
    }}
, '!'

adminConf = configFact outputAdmin,
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}

# modify staging settings that are only needed for staging
# (we may want to have an organized staging vs. prod config defined
#   that accounts for special cases / exceptions-to-the-rule that
#   we're hitting right now)
stagingConfs = [conf, adminConf]
_.merge(c, {'devtool': '#eval'}) for c in stagingConfs

# webpack task mgmt
runWebpack = (someConfig, app='rmap') ->
  gulp.src [
    paths[app].assets
    paths[app].styles
    paths[app].less
    paths[app].rootStylus
    paths[app].jade
    paths[app].html
    paths[app].webpackLibs
    paths[app].scripts
  ]
  .pipe plumber()
  .pipe(gWebpack someConfig)
  .pipe(gulp.dest(paths.dest.root))

gulp.task 'webpack', gulp.series 'otherAssets', 'webroot', ->
  runWebpack(conf)

gulp.task 'webpackProd', gulp.series 'otherAssets', 'webroot', ->
  runWebpack(prodConf)

gulp.task 'webpackAdmin', gulp.series 'otherAssets', 'webroot', ->
  runWebpack(adminConf, 'admin')

gulp.task 'webpackMap', gulp.series 'webpack'

gulp.task 'webpackApps', gulp.series 'clean', 'webpackMap', 'webpackAdmin'
