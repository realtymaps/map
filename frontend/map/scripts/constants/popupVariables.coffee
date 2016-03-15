app = require '../app.coffee'

app.constant 'rmapsPopupConstants',
  'default':
    offsets:
      top: 236
      bottom: 20
      left: 181
      right: -181
    templateFn: require('../../html/includes/map/_smallDetailsPopup.jade')
  'note':
    offsets:
      top: 200
      bottom: 20
      left: 150
      right: -150
    templateFn: require('../../html/includes/map/_notesPopup.jade')
  'mail':
    offsets:
      top: 147
      bottom: 5
      left: 181
      right: -181
    templateFn: require('../../html/includes/map/_mailPopup.jade')
