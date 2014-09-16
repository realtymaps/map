libFront = 'app/lib'

dest =
  scripts: 'scripts'
  styles: 'styles'
  fonts: 'fonts'
  assets: 'assets'
  root: '_public/'

module.exports =
  spec: 'spec/**'
  scripts: 'app/scripts/**'
  styles: 'app/styles/**/*.css'
  bower: 'bower_components'
  common: 'common/**'
  html: ['app/html/**/*.html','_public/index.html','!app/html/index.html']
  assets: 'app/assets/*'
  lib:
    front:
      scripts: libFront + '/scripts'
      styles: libFront + '/styles'
      fonts: libFront + '/fonts'
    back: 'backend/lib'

  dest: dest
  destFull:
    scripts: dest.root + dest.scripts
    styles: dest.root + dest.styles
    fonts: dest.root + dest.fonts
