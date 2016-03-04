{should, expect}= require('chai')
should()
sinon = require 'sinon'
subject = require "../../../../backend/utils/tasks/task.lob"
Promise = require 'bluebird'

findLettersTest = () ->
  tables.jobQueue.currentSubtasks()
  .select('*')
  .where name: 'lob_findLetters'
  .then (subtask) ->
    findLetters(subtask, createLetter)

findCampaignsTest = () ->
  tables.jobQueue.currentSubtasks()
  .select('*')
  .where name: 'lob_findCampaigns'
  .then (subtask) ->
    findCampaigns(subtask, chargeCampaign)


describe 'task.lob', ->
  it 'exists', ->
    expect(subject).to.be.ok
