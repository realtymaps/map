_ = require 'lodash'
require '../../../common/extensions/lodash.coffee'
require("chai").should()

describe 'lodash extensions', ->

  describe 'cleanObject', ->
    describe 'removals, default options', ->
      it 'null', ->
        obj =
          a: null
          b: 'test'
        _.cleanObject(obj).should.eql
          b:'test'

      it 'undefined', ->
        obj =
          a: undefined
          b: 'test'
        _.cleanObject(obj).should.eql
          b:'test'

      it 'emptyString', ->
        obj =
          a: ''
          b: 'test'
        _.cleanObject(obj).should.eql
          b:'test'

      it 'false', ->
        obj =
          a: ''
          b: 'test'
          c: false
        _.cleanObject(obj).should.eql
          b:'test'
          c: false

      it '0', ->
        obj =
          a: ''
          b: 'test'
          c: 0
        _.cleanObject(obj).should.eql
          b:'test'
          c: 0

      it 'float < 1', ->
        obj =
          a: ''
          b: 'test'
          c: 0.65
        _.cleanObject(obj).should.eql
          b:'test'
          c: 0.65

      it 'negative float', ->
        obj =
          a: ''
          b: 'test'
          c: -0.65
        _.cleanObject(obj).should.eql
          b:'test'
          c: -0.65

      it 'float > 1', ->
        obj =
          a: ''
          b: 'test'
          c: 1.65
        _.cleanObject(obj).should.eql
          b:'test'
          c: 1.65

    describe 'removals, options.null', ->
      it 'null', ->
        obj =
          a: null
          b: 'test'
        _.cleanObject(obj, null: true).should.eql
          b:'test'

      it 'undefined', ->
        obj =
          a: undefined
          b: 'test'
        _.cleanObject(obj,null: true).should.eql
          a: undefined
          b:'test'

      it 'emptyString', ->
        obj =
          a: ''
          b: 'test'
        _.cleanObject(obj,null: true).should.eql
          a: ''
          b:'test'

    describe 'removals, options.undefined', ->
      it 'null', ->
        obj =
          a: null
          b: 'test'
        _.cleanObject(obj, undefined: true).should.eql
          a: null
          b:'test'

      it 'undefined', ->
        obj =
          a: undefined
          b: 'test'
        _.cleanObject(obj, undefined: true).should.eql
          b:'test'

      it 'emptyString', ->
        obj =
          a: ''
          b: 'test'
        _.cleanObject(obj, undefined: true).should.eql
          a: ''
          b:'test'

    describe 'removals, options.emptyString', ->
      it 'null', ->
        obj =
          a: null
          b: 'test'
        _.cleanObject(obj, emptyString: true).should.eql
          a: null
          b:'test'

      it 'undefined', ->
        obj =
          a: undefined
          b: 'test'
        _.cleanObject(obj, emptyString: true).should.eql
          a: undefined
          b:'test'

      it 'emptyString', ->
        obj =
          a: ''
          b: 'test'
        _.cleanObject(obj, emptyString: true).should.eql
          b:'test'
