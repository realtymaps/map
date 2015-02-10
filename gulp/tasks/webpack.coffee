gulp = require 'gulp'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'
fs = require 'fs'

mockIndexes = fs.readdirSync(paths.mockIndexes)

#end dependencies
output =
  filename: paths.dest.scripts + "/[name].wp.js"
  chunkFilename: paths.dest.scripts + "/[id].wp.js"

conf = configFact(output, [new HtmlWebpackPlugin template: paths.index])
mockConf = configFact(output, mockIndexes.map (fileName) ->
  new HtmlWebpackPlugin
    template: paths.mockIndexes + '/' + fileName
    filename: "mocks/#{fileName}"
)

gulp.task 'webpack', ['otherAssets'], ->
  gulp.src [
    paths.assets
    paths.styles
    paths.stylus
    paths.jade
    paths.html
    paths.webpackLibs
    paths.scripts
  ]
  .pipe plumber()
  .pipe(gWebpack conf)
  .pipe(gulp.dest(paths.dest.root))
###
autopolyfill-loader, looking at lines 22~25 look to be invalid
the 'polyfill/source path does not exist under polyfill-service at all'
lastly the polyfill-service is deprecated (see https://github.com/deepsweet/autopolyfiller-loader/issues/1)
and is now at. I tried to update the dependencies with a realtymaps/autopolyfiller-loader but
i get callstack out of memory errors.
polyfills.forEach(function(polyfill) {
    inject += 'require("' + require.resolve('polyfill/source/' + polyfill) + '");';
    inject += '\n';
});
###
#paths.destFull.scripts + '/**/*' #for postLoader to polyfill the (FAILS via vendor.js PROMISE not found)

gulp.task 'webpackMock', ['otherAssets'], ->
  gulp.src [
    paths.assets
    paths.styles
    paths.stylus
    paths.jade
    paths.html
    paths.scripts
  ]
  .pipe plumber()
  .pipe(gWebpack mockConf)
  .pipe(gulp.dest(paths.dest.root))
