app = require '../scripts/app.coffee'

# should refresh browser
# https://github.com/angular-ui/ui-router/issues/105
app.run ['$state','$stateParams',($state, $stateParams) ->]