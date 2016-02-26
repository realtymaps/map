describe 'rmapsMailWizardCtrl', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject ($controller, $rootScope, $q, rmapsMailTemplateFactory) =>
      @state = # $state needs to compliment a scenario for rmapsMailWizardCtrl to create new campaign via factory
        current:
          name: 'recipientInfo'
        params: {}
      @$controller = $controller
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()
      @rmapsMailTemplateFactory = rmapsMailTemplateFactory

  describe 'controller behavior', ->
    xit 'vetting controller logic', (done) ->
      controller = @$controller 'rmapsMailWizardCtrl', { $scope: @scope, $state: @state }
      @scope.ready()
      .then () =>
        expect(@scope.wizard.mail).to.be.ok
        done()

