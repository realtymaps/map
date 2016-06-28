_ = require 'lodash'

describe 'Permissions'.ns('Common'), ->
  before ->
    somePermissions = [
      'presents'
      'tree'
      'cookies'
      'santa'
    ]
    @all =
      all: somePermissions
    @any =
      any: somePermissions
    @subject = require '../../../common/utils/permissions.coffee'
    @both = _.merge {}, @all, @any

  describe 'checkedAllowed', ->
    describe 'any as string', ->
      it 'has one', ->
        @allowedMap =
          tree: true
        @subject.checkAllowed('tree', @allowedMap).should.be.ok
      it 'has some', ->
        @allowedMap =
          tree: true
          christmas: true
        @subject.checkAllowed('christmas', @allowedMap).should.be.ok
      it 'has none', ->
        @allowedMap = {}
        @subject.checkAllowed('christmas', @allowedMap).should.not.be.ok

    describe 'any', ->
      it 'has one', ->
        @allowedMap =
          tree: true
        @subject.checkAllowed(@any, @allowedMap).should.be.ok
      it 'has some', ->
        @allowedMap =
          tree: true
          christmas: true
        @subject.checkAllowed(@any, @allowedMap).should.be.ok
      it 'has none', ->
        @allowedMap = {}
        @subject.checkAllowed(@any, @allowedMap).should.not.be.ok

    describe 'all', ->
      it 'has one', ->
        @allowedMap =
          tree: true
        @subject.checkAllowed(@all, @allowedMap).should.not.be.ok
      it 'has some', ->
        @allowedMap =
          tree: true
          christmas: true
        @subject.checkAllowed(@all, @allowedMap).should.not.be.ok
      it 'has none', ->
        @allowedMap = {}
        @subject.checkAllowed(@all, @allowedMap).should.not.be.ok

      it 'has all', ->
        tree: true
        christmas: true
        cookies: true
        presents: true

        @subject.checkAllowed(@all, @allowedMap).should.not.be.ok


    describe 'any takes precedence', ->
      it 'has one', ->
        @allowedMap =
          tree: true
        @subject.checkAllowed(@both, @allowedMap).should.be.ok
      it 'has some', ->
        @allowedMap =
          tree: true
          christmas: true
        @subject.checkAllowed(@both, @allowedMap).should.be.ok
      it 'has none', ->
        @allowedMap = {}
        @subject.checkAllowed(@both, @allowedMap).should.not.be.ok
