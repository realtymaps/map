login = require './utils/login'
Promise = require 'bluebird'

###globals by, element, browser###

describe 'Login: ', ->

  beforeAll ->
    login()

  it 'location is at /map', ->
    Promise.delay 1000
    .then ->
      expect(browser.getLocationAbsUrl()).toEqual('/map')

  it 'map is visible', () ->
    Promise.delay 1000
    .then ->
      expect(element(`by`.id('mainMap1')).isPresent()).toBeTruthy()
