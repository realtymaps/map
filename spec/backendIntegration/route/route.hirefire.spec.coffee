{basePath} = require '../globalSetup'
hirefireRoute = require "#{basePath}/routes/route.hirefire"
{expectResolve, expectReject, promiseIt} = require('../../specUtils/promiseUtils')


describe "route.hirefire", ->

  it 'should run the hirefire route with no errors', () ->
    this.timeout(30000)
    hirefireRoute.info()
