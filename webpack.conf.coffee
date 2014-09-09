webpack = require 'webpack'
_ = require 'lodash'

Config = (output, additionalPlugs) ->
  obj =
#    watch:true
    verbose:true
    devtool: '#source-map'#'#inline-source-map'
    resolve:
      modulesDirectories: ['bower_components','node_modules']
    plugins: [
        new webpack.ResolverPlugin(
          new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin(
            "bower.json", ["main"])
        )
      ]
    module:
      loaders: [
        { test: /\.css$/, loader: 'style!css' }
        { test: /\.styl$/, loader: 'style!css!stylus' }
        { test: /\.scss$/, loader: "style!css!sass?outputStyle=expanded"}
        { test: /\.coffee$/, loader: 'coffee' }
        { test: /\.png/, loader: 'url?limit=100000&minetype=image/png' }
        { test: /\.jpg/, loader: 'file' }
        {
          test: /\.woff$/,
          loader:"url?prefix=font/&limit=5000&mimetype=application/font-woff"
        }
        { test: /\.ttf$/, loader: "file?prefix=font/" }
        { test: /\.eot$/, loader: "file?prefix=font/" }
        { test: /\.svg$/, loader: "file?prefix=font/" }
      ]
  if output
    # console.info "APPLYING OUTPUT!!! #{_.values(output)}"
    obj.output = output
  if additionalPlugs
    obj.plugins = obj.plugins.concat(additionalPlugs)

  # console.log "Config object: " + _.values obj
  obj


#console.log "Config Class: " + Config
#instance = Config()
#console.log "Config Instance: " + instance
module.exports = Config
