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
            phrase = "montezuma's revenge"
            err = new classz(phrase)
            str = err.toString()
            str.should.be.equal "#{err.name}: #{phrase}"
            (-> throw err).should.throw(phrase)
