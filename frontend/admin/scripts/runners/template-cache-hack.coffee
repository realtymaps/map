app = require '../app.coffee'
app.run ($templateCache) ->

  #alias fix
  $templateCache.put('angular-busy.html', $templateCache.get('./angular-busy.html'))
