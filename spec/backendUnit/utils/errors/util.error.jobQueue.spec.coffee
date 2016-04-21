require("chai").should()
Promise = require 'bluebird'
_ = require 'lodash'
{SoftFail, HardFail} = require '../../../../backend/utils/errors/util.error.jobQueue'

describe 'util.error.jobQueue', ->
  for name, classz of {HardFail: HardFail,SoftFail: SoftFail}
    do (name, classz) ->
      describe name, ->

        beforeEach ->
          @subject = classz

        it 'exists', ->
          @subject.should.be.ok

        describe 'throws', ->
          it 'with correct name', ->
            err = new classz("montezuma's revenge")
            err.toString().should.have.string "#{name}: montezuma's revenge"
            (-> throw err).should.throw(/montezuma's revenge/)
