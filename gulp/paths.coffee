mapApp = 'frontend/map/'
adminApp = 'frontend/admin/'
libFront = mapApp + 'lib'

dest =
  scripts: 'scripts'
  styles: 'styles'
  fonts: 'fonts'
  assets: 'assets'
  root: '_public/'

module.exports =
  bower: 'bower_components'
  spec: 'spec/**'
  common: 'common/**/*.*'

  scripts: mapApp + 'scripts/**/*'
  vendorLibs: mapApp + 'lib/scripts/vendor/**/*.*'
  webpackLibs: mapApp + 'lib/scripts/webpack/**/*.*'
  styles: mapApp + 'styles/*.css'
  stylus: mapApp + 'styles/main.styl'
  stylusWatch: mapApp + 'styles/**/*.styl'
  svg: mapApp + 'html/svg/*.svg'
  html: mapApp + 'html/**/*.html'
  jade: mapApp + 'html/**/*.jade'
  json: mapApp + 'json/**/*.json'
  mockIndexes: mapApp + 'html/mocks'
  index: mapApp + 'html/index.html'
  assets: mapApp + 'assets/*'
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
    index: dest.root + 'index.html'
