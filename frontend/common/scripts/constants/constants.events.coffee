
keysToValues = require '../../../../common/utils/util.keysToValues.coffee'
mod = require '../module.coffee'

mod.constant 'rmapsEventConstants',
  keysToValues
    notes: 1
    neighbourhoods:
      createClick: 1
      dropdownToggled: 1
      drawItems: 1
      removeDrawItem: 1
    map:
      locationChange: 1
      results: 1
      center: 1
      centerOnProperty: 1
      zoomToProperty: 1
      fitBoundsProperty: 1
      mainMap:
        redraw: 1
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
      logout:
        success: 1
      profile:
        updated: 1
        add: 1
    alert:
      spawn: 1
      hide: 1
      dismiss: 1
      prevent: 1
    snail:
      initiateSend: 1
    update:
      properties:
        pin: 1
        favorite: 1
