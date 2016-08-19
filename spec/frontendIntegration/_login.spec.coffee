login = require './utils/login'
Promise = require 'bluebird'

###globals by, element, browser###

describe 'Login: ', ->

  beforeAll ->
    login()

  it 'location is at /map', ->
    expect(browser.getLocationAbsUrl()).toEqual('/map')

  it 'map is visible', () ->
    Promise.delay 1000
    .then ->
      expect(element(`by`.id('mainMap1')).isPresent()).toBeTruthy()


  # it 'Retangle Area is selected on drawing', () ->
  #   element(`by`.css('.dropdown.btn-group.area-list')).click()
  #   element(`by`.css('.draw-area-btn')).click()
  #
  #   el = element(`by`.css('.leaflet-draw-tooltip.leaflet-draw-tooltip-single'))
  #   expect(el.isPresent()).toBeTruthy()
  #   expect(el.getText()).toEqual('Click and drag to draw rectangle.')
