app = require '../app.coffee'

app.factory 'MapToggles'.ourNs(), [
  () ->
    
    showResults: false
    showDetails: false
    showFilters: false

    # TODO - add a function to manage which trays are opened / closed    

  ]
