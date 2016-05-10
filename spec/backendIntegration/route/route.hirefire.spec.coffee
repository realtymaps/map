{basePath} = require '../globalSetup'
hirefireRoute = require "#{basePath}/routes/route.hirefire"
hirefireService = require "#{basePath}/services/service.hirefire"
ExpressResponse = require "#{basePath}/utils/util.expressResponse"
require("chai").should()


# technically this is testing both route.hirefire and service.hirefire, but I left it combined because that ensures we
# won't get spurious errors messages in the testing logs about not having updated the queue needs in too long

describe "route.hirefire", ->

  it 'should run the hirefire update with no errors, and the route should send the results calculated previously', () ->
    this.timeout(30000)
    hirefireService.updateQueueNeeds()
    .then (needs) ->
      hirefireRoute.info null, null, (result) ->
        (result instanceof ExpressResponse).should.be.truthy
        JSON.stringify(result.payload).should.equal(JSON.stringify(needs))
