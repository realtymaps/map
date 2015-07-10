app = require '../app.coffee'
interceptors = require '../../../common/scripts/factories/interceptors.coffee'

app.factory 'rmapsRedirectInterceptor', interceptors.rmapsRedirectInterceptor
app.factory 'rmapsAlertInterceptor', interceptors.rmapsAlertInterceptor
app.factory 'rmapsLoadingIconInterceptor', interceptors.rmapsLoadingIconInterceptor
app.config interceptors.pushInterceptors
