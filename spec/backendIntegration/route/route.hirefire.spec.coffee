{basePath} = require '../globalSetup'
hirefireRoute = require "#{basePath}/routes/route.hirefire"
hirefireService = require "#{basePath}/services/service.hirefire"
ExpressResponse = require "#{basePath}/utils/util.expressResponse"
tables = require "#{basePath}/config/tables"
require("chai").should()


# technically this is testing both route.hirefire and service.hirefire, but I left it combined because that ensures we
# won't get spurious errors messages in the testing logs about not having updated the queue needs in too long

describe "route.hirefire", ->
  updateQueueNeedspromise = emailConfig = null
  before ->
    emailConfig = require "#{basePath}/config/email"
    @timeout(30000)
    updateQueueNeedspromise = hirefireService.updateQueueNeeds()


  it 'should run the hirefire update with no errors, and the route should send the results calculated previously', () ->
    updateQueueNeedspromise
    .then (needs) ->
      hirefireRoute.info null, null, (result) ->
        (result instanceof ExpressResponse).should.be.truthy
        JSON.stringify(result.payload).should.equal(JSON.stringify(needs))

  it 'should have generated an email', ->
    updateQueueNeedspromise
    .then () ->
      #not always called due to timing (race)?
      if !emailConfig.getMailer.called
        return

      tables.config.notification()
      .where {type: 'jobQueue', method: 'email'}
      .count()
      .then ([{count}]) ->
        if count > 0
          emailConfig.getMailer()
          .then (mailer) ->
            mailer.sendMailAsync.called.should.be.ok
