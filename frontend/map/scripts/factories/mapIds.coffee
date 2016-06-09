app = require '../app.coffee'
console.log "!!!!!!!! MAP IDS FACTORY"

app.service 'rmapsMapIds', () ->
  mainMapIndex = 1
  mainMapBase = 'mainMap'

  service = {}

  service.incrementMainMap = () ->
    mainMapIndex += 1

  service.mainMap = () ->
    return mainMapBase + mainMapIndex

  return service
