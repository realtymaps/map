
keysToValues = require '../../../../common/utils/util.keysToValues.coffee'
mod = require '../module.coffee'

mod.constant 'rmapsevents',
  keysToValues
    notes: 1
    neighborhoods: 1
    map:
      drawPolys:
        isEnabled: 1
        clear: 1
        query:  1
      filters:
        updated: 1
      properties:
        pin: 1
        favorite: 1
    principal:
      login:
        success: 1
      profile:
        updated: 1
    alert:
      spawn: 1
      hide: 1
      dismiss: 1
      prevent: 1
    snail:
      initiateSend: 1
