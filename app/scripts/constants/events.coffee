app = require '../app.coffee'

app.constant 'events'.ourNs(),
  map:
    drawPolys:
      isEnabled: 'map.drawPolys.isEnabled'
      clear: 'map.drawPolys.clear'
      query:  'map.drawPolys.query'