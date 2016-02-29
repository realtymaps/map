describe 'rmapsMailWizardCtrl', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject ($controller, $rootScope, $q, digestor, rmapsMailTemplateFactory) =>
      @digestor = digestor
      @state = # $state needs to compliment a scenario for rmapsMailWizardCtrl to create new campaign via factory
        current:
          name: 'recipientInfo'
        params: {}
      @$controller = $controller
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()
      @rmapsMailTemplateFactory = rmapsMailTemplateFactory

  describe 'controller behavior', ->
    it 'vetting controller logic', (done) ->
      controller = @$controller 'rmapsMailWizardCtrl', { $scope: @scope, $state: @state }
      logic = @scope.ready()
      .then () =>
        expect(@scope.wizard.mail).to.be.ok
        done()

      @digestor.digest @scope, logic

