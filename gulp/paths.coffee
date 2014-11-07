libFront = 'app/lib'

dest =
  scripts: 'scripts'
  styles: 'styles'
  fonts: 'fonts'
  assets: 'assets'
  root: '_public/'

module.exports =
  spec: 'spec/**'
  scripts: 'app/scripts/**/*.*'
  styles: 'app/styles/**/*.css'
  stylus: 'app/styles/**/*.styl'
  bower: 'bower_components'
  common: 'common/**/*.*'
  svg: 'app/html/svg/*.svg'
  html: 'app/html/**/*.html'
  jade: 'app/html/**/*.jade'
  index: 'app/html/index.html'
  assets: 'app/assets/*'
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
