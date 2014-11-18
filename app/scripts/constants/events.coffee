app = require '../app.coffee'

app.constant 'events'.ourNs(),
  map:
    drawPolys:
      isEnabled: 'map.drawPolys.isEnabled'
      clear: 'map.drawPolys.clear'
      need:  'map.drawPolys.need'
      here:  'map.drawPolys.here'
