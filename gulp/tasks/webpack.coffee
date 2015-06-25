gulp = require 'gulp'
require './otherAssets'
gWebpack = require 'webpack-stream'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'
fs = require 'fs'
webpack = require 'webpack'
jade = require 'jade'
newrelic = require 'newrelic'

mockIndexes = fs.readdirSync(paths.rmap.mockIndexes)

# outputs
output =
  filename: paths.dest.scripts + "/[name].wp.js"
  chunkFilename: paths.dest.scripts + "/[id].wp.js"

outputAdmin =
  filename: paths.dest.scripts + "/admin.wp.js"
  chunkFilename: paths.dest.scripts + "/adminChunk.wp.js"

# webpack confs per each environment & app
conf = configFact output, [
  new HtmlWebpackPlugin
    templateContent: (templateParams, compilation, callback) ->
      fs.readFile paths.rmap.index, "utf8",  (err, data) ->
        callback(null, jade.render(data, {newrelic: newrelic.getBrowserTimingHeader(), pretty:true}))
    filename: "rmap.html"
]

mockConf = configFact output, mockIndexes.map (fileName) ->
  new HtmlWebpackPlugin
    template: paths.mockIndexes + '/' + fileName
    filename: "mocks/#{fileName}"

prodConf = configFact output, [
  new HtmlWebpackPlugin
    templateContent: (templateParams, compilation, callback) ->
      fs.readFile paths.rmap.index, "utf8",  (err, data) ->
        callback(null, jade.render(data, {newrelic: newrelic.getBrowserTimingHeader(), pretty:true}))
    filename: "rmap.html"
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
], '!'

adminConf = configFact outputAdmin, [
  new HtmlWebpackPlugin
    templateContent: (templateParams, compilation, callback) ->
      fs.readFile paths.admin.index, "utf8",  (err, data) ->
        callback(null, jade.render(data, {newrelic: newrelic.getBrowserTimingHeader(), pretty:true}))
    filename: "admin.html"
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
]

# modify staging settings that are only needed for staging
# (we may want to have an organized staging vs. prod config defined
#   that accounts for special cases / exceptions-to-the-rule that
#   we're hitting right now)
stagingConfs = [conf, mockConf, adminConf]
_.merge(c, {'devtool': '#eval'}) for c in stagingConfs

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

gulp.task 'webpack', gulp.series 'otherAssets', ->
  runWebpack(conf)

gulp.task 'webpackMock', gulp.series 'otherAssets', ->
  runWebpack(mockConf)

gulp.task 'webpackProd', gulp.series 'otherAssets', ->
  runWebpack(prodConf)

gulp.task 'webpackAdmin', gulp.series 'otherAssets', ->
  runWebpack(adminConf, 'admin')
