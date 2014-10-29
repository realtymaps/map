app = require '../app.coffee'

app.factory 'MapToggles'.ourNs(), [
  () ->
    
    showResults: true
    showDetails: false

    toggle: () ->
      alert 'hello'
    

  ]
