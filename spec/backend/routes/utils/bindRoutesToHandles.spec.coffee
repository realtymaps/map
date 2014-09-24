subject = require '../../../../backend/routes/utils/bindRoutesToHandles'

describe 'bindRoutesToHandles', ->
  beforeEach ->
    @app = sinon.mock get: (res,resp) ->

  it 'exists', ->
    subject.should.be.ok

  it '3 routes & handles should be called 3 times', ->
    spy = sinon.spy()
    routeHandles = [
      '/one'
      '/two'
      '/three'
    ].map (r) ->
      route: r
      handle: spy

    @app.expects('get').thrice()

    #fullfill
    subject @app.object, routeHandles

    @app.verify()

  it 'unmatched routes to handles should throw', ->

    routeHandles = [
      '/one'
      '/two'
    ].map (r) ->
      route: r
      handle: ->

    routeHandles.push route: '/three'

    @app.expects('get').twice()

    #fullfill , could not get ( -> ).should.throw() to work at all
    try
      subject @app.object, routeHandles
    catch
      error = true

    @app.verify()
    error.should.be.ok
