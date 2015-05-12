app = require '../app.coffee'
keysToValues = require '../../../common/utils/util.keysToValues.coffee'

app.constant 'events'.ourNs(),
  keysToValues
    map:
      drawPolys:
        isEnabled: 1
        clear: 1
        query:  1
    principal:
      login:
        success: 1
    alert:
      spawn: 1
      hide: 1
      dismiss: 1
      prevent: 1
    snail:
      initiateSend: 1
