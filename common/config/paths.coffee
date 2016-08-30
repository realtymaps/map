appMap = 'map'
appAdmin = 'admin'
libFront = appMap + 'lib'

dest =
  scripts: 'scripts'
  styles: 'styles'
  fonts: 'fonts'
  assets: 'assets'
  json: 'json'
  root: '_public/'

getAssetCollection = (name) ->
  app = "frontend/#{name}/"
  return {
    name: name
    appName: "rmaps#{name.toInitCaps()}App"
    root: app
    scripts: app + 'scripts/**/*'
    vendorLibs: app + 'lib/scripts/vendor/**/*.*'
    webpackLibs: app + 'lib/scripts/webpack/**/*.*'
    styles: app + 'styles/**/*.css'
    rootStylus: app + 'styles/main.styl'
    stylus: app + 'styles/**/*.styl'
    less: app + 'styles/**/*.less'
    svg: app + 'html/svg/*.svg'
    html: [app + 'html/**/*.html', "frontend/common/html/**/*.html"]
    jade: [app + 'html/**/*.jade', "frontend/common/html/**/*.jade"]
    json: app + 'json/**/*.json'
    assets: app + 'assets/**/*.*'
  }

module.exports =
  bower: 'bower_components'
  spec: 'spec/**'
  common: 'common/**/'
  backend: 'backend/**/'
  webroot: 'common/webroot/**/*.*'

  frontendCommon: getAssetCollection('common')
  map: getAssetCollection(appMap)
  admin: getAssetCollection(appAdmin)

  lib:
    front:
      scripts: libFront + '/scripts'
      styles: libFront + '/styles'
      fonts: libFront + '/fonts'
    back: 'backend/lib'

  dest: dest
  destFull:
    assets: dest.root + dest.assets
    scripts: dest.root + dest.scripts
    styles: dest.root + dest.styles
    fonts: dest.root + dest.fonts
    json: dest.root + dest.json
    index: dest.root + 'rmap.html'
    admin: dest.root + 'admin.html'
    bundle:
      map: dest.scripts + '/map.bundle.js'
      admin: dest.scripts + '/admin.bundle.js'
    templates:
      map: dest.scripts + '/map.templates.js'
      admin: dest.scripts + '/admin.templates.js'
    webpack:
      map:
        # publicPath: 'http://0.0.0.0:4000/'#for dev only, https://github.com/webpack/style-loader/issues/55, https://github.com/webpack/css-loader/issues/29
        filename: dest.scripts + '/main.wp.js'
        chunkFilename: dest.scripts + '/main.wp.js'
      admin:
        # publicPath: 'http://0.0.0.0:4000/'#for dev only
        filename: dest.scripts + '/admin.wp.js'
        chunkFilename: dest.scripts + '/adminChunk.wp.js'
