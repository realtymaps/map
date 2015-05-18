gulp = require 'gulp'
require './otherAssets'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'
fs = require 'fs'
webpack = require 'webpack'

mockIndexes = fs.readdirSync(paths.rmap.mockIndexes)

# outputs
output =
  filename: paths.dest.scripts + "/[name].wp.js"
  chunkFilename: paths.dest.scripts + "/[id].wp.js"

outputAdmin =
  filename: paths.dest.scripts + "/admin.wp.js"
  chunkFilename: paths.dest.scripts + "/adminChunk.wp.js"

# webpack confs per each environment & app
conf = configFact(output, [new HtmlWebpackPlugin
  template: paths.rmap.index
  filename: "rmap.html"
])
mockConf = configFact(output, mockIndexes.map (fileName) ->
  new HtmlWebpackPlugin
    template: paths.mockIndexes + '/' + fileName
    filename: "mocks/#{fileName}"
)
prodConf = configFact(output, [
  new HtmlWebpackPlugin
    template: paths.rmap.index
    filename: "rmap.html"
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
], '!')
adminConf = configFact(outputAdmin, [
  new HtmlWebpackPlugin
    template: paths.admin.index
    filename: "admin.html"
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
])

# modify staging settings that are only needed for staging
# (we may want to have an organized staging vs. prod config defined
#   that accounts for special cases / exceptions-to-the-rule that
#   we're hitting right now)
conf.devtool = '#eval'
mockConf.devtool = '#eval'
adminConf.devtool = '#eval'

# webpack task mgmt
runWebpack = (someConfig, app='rmap') ->
  gulp.src [
    paths[app].assets
    paths[app].styles
    paths[app].stylus
    paths[app].jade
    paths[app].html
    paths[app].webpackLibs
    paths[app].scripts
  ]
  .pipe plumber()
  .pipe(gWebpack someConfig)
  .pipe(gulp.dest(paths.dest.root))

gulp.task 'webpack', gulp.parallel 'otherAssets', ->
  runWebpack(conf)

gulp.task 'webpackMock', gulp.parallel 'otherAssets', ->
  runWebpack(mockConf)

gulp.task 'webpackProd', gulp.parallel 'otherAssets', ->
  runWebpack(prodConf)

gulp.task 'webpackAdmin', gulp.parallel 'otherAssets', ->
  runWebpack(adminConf, 'admin')
