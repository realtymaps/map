app = require '../app.coffee'

app.service 'rmapsMapIds', () ->
  mainMapIndex = 1
  mainMapBase = 'mainMap'

  service = {}

  service.incrementMainMap = () ->
    mainMapIndex += 1

  service.mainMap = () ->
    # just returning the ID and reusing a single instance almost seems to work,
    # except some of the area and draw logic becomes messed up
    # return "#{mainMapBase}1"

    return mainMapBase + mainMapIndex

  return service
