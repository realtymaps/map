app = require '../app.coffee'

app.controller 'rmapsOnBoardingPlanCtrl', ($scope) ->

  $scope.plan = 'standard'

  $scope.getSelected = (planStr) ->
    if $scope.plan == planStr then 'selected' else 'select'

  $scope.setPlan = (newPlan) ->
    $scope.plan = newPlan

app.controller 'rmapsOnBoardingPayment', ($scope) ->
app.controller 'rmapsOnBoardingLocation', ($scope) ->
