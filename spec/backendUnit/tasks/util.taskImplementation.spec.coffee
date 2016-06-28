sinon = require 'sinon'
chai = require("chai")
chai.use(require 'chai-as-promised')
chai.should()
{basePath} = require '../globalSetup'
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
          subject.executeSubtask(name: undefined).should
          .be.rejectedWith(errors.TaskNameError, 'subtask.name must be defined')

        it 'null', ->
          subject.executeSubtask(name: null).should
          .be.rejectedWith(errors.TaskNameError, 'subtask.name must be defined')

        it 'non existent name', ->
          subtaskName = 'missing'
          subject.executeSubtask(name: subtaskName).should
          .be.rejectedWith(errors.TaskNameError,
          """Task name is not contained in subtask name.
          Where the valid format is taskname_subtaskname.
          For subtask: #{subtaskName}.""".replace(/\n/g, ' '))

        it 'bad _ order post _test', ->
          subtaskName = 'one_test'
          subject.executeSubtask(name: subtaskName).should
          .be.rejectedWith(errors.TaskNameError,
          """Task name is not contained in subtask name.
          Where the valid format is taskname_subtaskname.
          For subtask: #{subtaskName}.""".replace(/\n/g, ' '))

        it 'bad _ order post _test 2', ->
          subtaskName = '1test_one'
          subject.executeSubtask(name: subtaskName).should
          .be.rejectedWith(errors.TaskNameError,
          """Task name is not contained in subtask name.
          Where the valid format is taskname_subtaskname.
          For subtask: #{subtaskName}.""".replace(/\n/g, ' '))

        it 'bad order post test', ->
          subtaskName = 'testone'
          subject.executeSubtask(name: subtaskName).should
          .be.rejectedWith(errors.TaskNameError,
          """Task name is not contained in subtask name.
          Where the valid format is taskname_subtaskname.
          For subtask: #{subtaskName}.""".replace(/\n/g, ' '))

      describe 'MissingSubtaskError', ->

        it 'no subtask', ->
          subtaskName = 'test_'
          subject.executeSubtask(name: subtaskName).should
          .be.rejectedWith(errors.MissingSubtaskError,
          """Can't find subtask code for #{subtaskName},
          subtasks: #{Object.keys(subject.subtasks).join(',')} aval!!"""
          .replace(/\n/g, ' '))

        it 'non-existent subtask', ->
          subtaskName = 'test_four'
          subject.executeSubtask(name: subtaskName).should
          .be.rejectedWith(errors.MissingSubtaskError,
          """Can't find subtask code for #{subtaskName},
          subtasks: #{Object.keys(subject.subtasks).join(',')} aval!!"""
          .replace(/\n/g, ' '))

        Object.keys(makeSubtasks()).forEach (name) ->
          it "correct subtask #{name}", ->
            subtaskName = 'test_' + name
            subject.executeSubtask(name: subtaskName)
