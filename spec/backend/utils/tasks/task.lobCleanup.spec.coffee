{should, expect}= require('chai')
should()
# sinon = require 'sinon'
basePath = require '../../basePath'
subject = require "#{basePath}/utils/tasks/task.lobCleanup"
# Promise = require 'bluebird'

describe 'task.lobCleanup', ->
  it 'exists', ->
    expect(subject).to.be.ok
