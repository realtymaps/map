_ = require 'lodash'
app = require '../app.coffee'

_events = [
  'click'
  'mouseover'
  'mouseout'
  'dblclick'
]

_eventsToObj = (key) ->
  _.zipObject _events.map (name) ->
    [name, key + ':' + name]

obj = _.zipObject ['map','window', 'marker', 'geojson', 'drawnShapes']

# coffeelint: disable=check_scope
for key, val of obj
# coffeelint: enable=check_scope
  obj[key] = _eventsToObj key

app.constant 'rmapsMapEventEnums', obj
