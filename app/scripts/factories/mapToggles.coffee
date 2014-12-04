app = require '../app.coffee'

app.factory 'MapToggles'.ourNs(), [
  () ->
    
    showResults: false #tired of closing this at start (please get this right if we re-enable it)
    showDetails: false

    toggle: () ->
      alert 'hello'
    

  ]
