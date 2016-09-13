### globals angular, inject###

describe 'cartodb', () ->
  subject = null

  beforeEach ->
    angular.mock.module 'rmapsMapApp'
    inject ($rootScope, rmapsCartoDb) ->
      subject = rmapsCartoDb

  describe 'baseRoute', () ->
    it 'exists', () ->
      subject.baseRoute.should.be.ok
