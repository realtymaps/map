{should, expect}= require('chai')
should()
sinon = require 'sinon'
basePath = require '../../basePath'
subject = require "#{basePath}/utils/tasks/task.lob"
Promise = require 'bluebird'

findLettersTest = () ->
  tables.jobQueue.currentSubtasks()
  .select('*')
  .where name: 'lob_findLetters'
  .then (subtask) ->
    findLetters(subtask, sendLetter)

findCampaignsTest = () ->
  tables.jobQueue.currentSubtasks()
  .select('*')
  .where name: 'lob_findCampaigns'
  .then (subtask) ->
    findCampaigns(subtask, chargeCampaign)


describe 'task.lob', ->
  it 'exists', ->
    expect(subject).to.be.ok
