libFront = 'app/lib'

module.exports =
  scripts: 'app/scripts/**'
  styles: 'app/styles/**/*.css'
  bower: 'bower_components'
  html: ['app/html/**/*.html','_public/index.html','!app/html/index.html']
  assets: 'app/assets/*'
  lib:
    front:
      scripts: libFront + '/scripts'
      styles: libFront + '/styles'
      fonts: libFront + '/fonts'
    back: 'backend/lib'

  dest:
    scripts: 'scripts'
    styles: 'styles'
    fonts: 'fonts'
    assets: 'assets'
    root: '_public/'