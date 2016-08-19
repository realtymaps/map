{basePath} = require '../globalSetup'
promiseUtils = require '../../specUtils/promiseUtils'
rewire = require('rewire')
TaskImplementation = rewire("#{basePath}/tasks/util.taskImplementation")
subject = null
taskName = null
errorHandlingUtils = require '../../../backend/utils/errors/util.error.partiallyHandledError'

makeSubtasks = () ->

describe 'util.taskImplementation', () ->

  taskName = 'test'
  subtasks =
    one: () ->
    two: () ->
    three: () ->

  fakeErrors = {
    TaskNameError: class FakeTaskNameError extends errorHandlingUtils.QuietlyHandledError
    MissingSubtaskError: class FakeMissingSubtaskError extends errorHandlingUtils.QuietlyHandledError
  }
  TaskImplementation.__set__('errors', fakeErrors)
  subject = new TaskImplementation taskName, subtasks

  describe 'executeSubtask', () ->
    describe 'throws', ->
      describe 'TaskNameError', () ->

        it 'undefined', ->
          promiseUtils.expectReject(subject.executeSubtask({name: undefined}), fakeErrors.TaskNameError)

        it 'null', ->
          promiseUtils.expectReject(subject.executeSubtask({name: null}), fakeErrors.TaskNameError)

        it 'non existent name', ->
          subtaskName = 'missing'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}), fakeErrors.TaskNameError)

        it 'bad _ order post _test', ->
          subtaskName = 'one_test'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}), fakeErrors.TaskNameError)

        it 'bad _ order post _test 2', ->
          subtaskName = '1test_one'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}), fakeErrors.TaskNameError)

        it 'bad order post test', ->
          subtaskName = 'testone'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}), fakeErrors.TaskNameError)

      describe 'MissingSubtaskError', ->

        it 'no subtask', ->
          subtaskName = 'test_'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}), fakeErrors.MissingSubtaskError)

        it 'non-existent subtask', ->
          subtaskName = 'test_four'
          promiseUtils.expectReject(subject.executeSubtask({name: subtaskName}), fakeErrors.MissingSubtaskError)

        for name of subtasks
          it "correct subtask #{name}", ->
            subtaskName = 'test_' + name
            promiseUtils.expectResolve(subject.executeSubtask({name: subtaskName}))
