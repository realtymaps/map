{basePath} = require '../globalSetup'
hirefireRoute = require "#{basePath}/routes/route.hirefire"
ExpressResponse = require "#{basePath}/utils/util.expressResponse"


describe "route.hirefire", ->

  it 'should run the hirefire route with no errors', () ->
    this.timeout(30000)
    hirefireRoute.info null, null, (result) ->
      (result instanceof ExpressResponse).should.be.truthy
