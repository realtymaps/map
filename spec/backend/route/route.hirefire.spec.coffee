basePath = require '../basePath'
hirefireRoute = require "#{basePath}/routes/route.hirefire"
{expectResolve, expectReject, promiseIt} = require('../../specUtils/promiseUtils')


describe "route.hirefire", ->

  if process.env.CIRCLECI
    it "can't run on CircleCI because this is an integration test involving the db", () ->
      #noop
    return

  it 'should run the hirefire route with no errors', () ->
    this.timeout(30000)
    hirefireRoute.info()
