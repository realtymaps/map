Promise = require 'bluebird'

describe 'Areas: ', ->

  it 'Retangle Area is selected on drawing', () ->
    Promise.delay 1000
    .then ->
      element(`by`.css('.dropdown.btn-group.area-list')).click()
      element(`by`.css('.draw-area-btn')).click()

      el = element(`by`.css('.leaflet-draw-tooltip.leaflet-draw-tooltip-single'))
      expect(el.isPresent()).toBeTruthy()
      expect(el.getText()).toEqual('Click and drag to draw rectangle.')
