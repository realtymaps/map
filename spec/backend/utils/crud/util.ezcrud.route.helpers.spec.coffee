_ = require 'lodash'
basePath = require '../../basePath'
RouteCrud = require "#{basePath}/utils/crud/util.ezcrud.route.helpers"
ServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.helpers"

describe 'util.ezcrud.route.helpers', ->
  beforeEach ->
    @svcMock = new ServiceCrud(->)

  describe 'RouteCrud', ->
    beforeEach ->
      @routeCrud = new RouteCrud(@svcMock)

    it 'passes sanity check', ->
      RouteCrud.should.be.ok
      @routeCrud.should.be.ok

    it 'fails instantiation without svc', ->
      (-> new RouteCrud()).should.throw()

