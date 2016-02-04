{should, expect}= require('chai')
should()
# sinon = require 'sinon'
basePath = require '../../basePath'
subject = require "#{basePath}/utils/tasks/task.stripe"
# Promise = require 'bluebird'

describe 'task.stripe', ->
  it 'exists', ->
    expect(subject).to.be.ok
