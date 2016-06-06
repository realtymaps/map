subject = require '../../../../frontend/map/scripts/utils/util.cartodb.coffee'

describe 'util.cartodb', () ->

  describe 'baseRoute', () ->
    it 'exists', () ->
      subject.baseRoute.should.be.ok
