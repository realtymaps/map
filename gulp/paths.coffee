appMap = 'frontend/map/'
appAdmin = 'frontend/admin/'
libFront = appMap + 'lib'

dest =
  scripts: 'scripts'
  styles: 'styles'
  fonts: 'fonts'
  assets: 'assets'
  root: '_public/'

getAssetCollection = (app) ->
  return {
    scripts: app + 'scripts/**/*'
    vendorLibs: app + 'lib/scripts/vendor/**/*.*'
    webpackLibs: app + 'lib/scripts/webpack/**/*.*'
    styles: app + 'styles/*.css'
    stylus: app + 'styles/main.styl'
    stylusWatch: app + 'styles/**/*.styl'
    svg: app + 'html/svg/*.svg'
    html: app + 'html/**/*.html'
    jade: app + 'html/**/*.jade'
    json: app + 'json/**/*.json'
    mockIndexes: app + 'html/mocks'
    index: app + 'html/index.jade'
    assets: app + 'assets/*'
  }


module.exports =
  bower: 'bower_components'
  spec: 'spec/**'
  common: 'common/**/*.*'

  rmap: getAssetCollection(appMap)
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
    index: dest.root + 'rmap.html'
    admin: dest.root + 'admin.html'
