app = require '../app.coffee'

app.config (toastrConfig) ->
  angular.extend toastrConfig,
    positionClass: 'toast-top-center'
    target: 'main'
