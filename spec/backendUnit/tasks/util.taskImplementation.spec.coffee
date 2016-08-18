sinon = require 'sinon'
chai = require("chai")
chai.use(require 'chai-as-promised')
chai.should()
{basePath} = require '../globalSetup'
promiseUtils = require '../../specUtils/promiseUtils'
rewire = require('rewire')
TaskImplementation = rewire("#{basePath}/tasks/util.taskImplementation")
errors = require("#{basePath}/utils/errors/util.errors.task")
subject = null
taskName = null

makeSubtasks = () ->
  one: sinon.stub()
  two: sinon.stub()
  three: sinon.stub()

describe 'util.taskImplementation', () ->

  beforeEach ->
    taskName = 'test'
    subtasks = makeSubtasks()
    subject = new TaskImplementation taskName, subtasks


  describe 'executeSubtask', () ->
    describe 'throws', ->
      describe 'TaskNameError', () ->

        it 'undefined', ->
          promiseUtils.expectReject(subject.executeSubtask({name: undefined}, {quiet: true}), errors.TaskNameError)

        it 'null', ->
          promiseUtils.expectReject(subject.executeSubtask({name: null}, {quiet: true}), errors.TaskNameError)

        it 'non existent name', ->
          subtaskName = 'missing'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}, {quiet: true}), errors.TaskNameError)

        it 'bad _ order post _test', ->
          subtaskName = 'one_test'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}, {quiet: true}), errors.TaskNameError)

        it 'bad _ order post _test 2', ->
          subtaskName = '1test_one'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}, {quiet: true}), errors.TaskNameError)

        it 'bad order post test', ->
          subtaskName = 'testone'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}, {quiet: true}), errors.TaskNameError)

      describe 'MissingSubtaskError', ->

        it 'no subtask', ->
          subtaskName = 'test_'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}, {quiet: true}), errors.MissingSubtaskError)

        it 'non-existent subtask', ->
          subtaskName = 'test_four'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}, {quiet: true}), errors.MissingSubtaskError)

        Object.keys(makeSubtasks()).forEach (name) ->
          it "correct subtask #{name}", ->
            subtaskName = 'test_' + name
            promiseUtils.expectResolve(subject.executeSubtask({name: subtaskName}, {quiet: true}))
