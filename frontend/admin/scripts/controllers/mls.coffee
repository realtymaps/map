app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

app.controller 'rmapsMlsCtrl', [ '$scope', '$state', 'rmapsMlsService'
  ($scope, $state, rmapsMlsService) ->

    console.log 'rmapsMlsCtrl'

    $scope.mock =
      db: ['dbOne', 'dbTwo']
      table: ['tableOne', 'tableTwo']
      field: ['fieldOne', 'fieldTwo']

    $scope.alert = ""

    $scope.mlsData =
      id: null
      name: null
      notes: null
      active: null
      username: null
      password: null
      url: null
      main_property_data:
        db: null
        table: null
        field: null
        queryTemplate: null
    $scope.adminRoutes = adminRoutes
    $scope.$state = $state

    $scope.step = 0

    isActive = (configStep) ->
      () ->
        return ($scope.step == configStep)

    $scope.formItems = [
      step: 0
      heading: "Select MLS"
      formFields:
        id:
          type: "text"
          label: "ID"
        name:
          type: "text"
          label: "Name"
        url:
          type: "text"
          label: "URL"
        username:
          type: "text"
          label: "Username"
        password:
          type: "password"
          label: "Password"
      validate: () ->
        thisValidates = true
        if thisValidates
          $scope.formItems[1].disabled = false
          console.log "#### Step 1 validated"
      disabled: false
      active: isActive(0)
    ,
      step: 1
      heading: "Choose Database"
      formFields:
        db:
          type: "select"
          label: "Database"
          options:
            one: "db1"
            two: "db2"
            three: "db3"
            four: "db4"
      validate: () ->
        thisValidates = true
        if thisValidates
          $scope.formItems[2].disabled = false
          console.log "#### Step 2 validated"
      disabled: true
      active: isActive(1)
    ,
      step: 2
      heading: "Choose Table"
      formFields:
        table:
          type: "select"
          label: "Table"
          options:
            one: "table1"
            two: "table2"
      validate: () ->
        thisValidates = true
        if thisValidates
          $scope.formItems[3].disabled = false
          console.log "#### Step 3 validated"
      disabled: true
      active: isActive(2)
    ,
      step: 3
      heading: "Choose Field"
      formFields:
        field:
          type: "select"
          label: "Field"
          options:
            one: "field1"
            two: "field2"
            three: "field3"
        query:
          type: "text"
          label: "Query Template"
          default: "[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]"
      validate: () ->
        thisValidates = true
        if thisValidates
          console.log "#### Step 4 validated"
      disabled: true
      active: isActive(3)
    ]

    $scope.proceedTo = (toStep) ->
      thisStep = $scope.step
      if toStep > thisStep
        # run proceed() of this step, which validates
        $scope.formItems[thisStep].validate()

      # incr active step if allowed
      if _.every($scope.formItems[..toStep], {disabled: false}) and toStep < ($scope.formItems.length)
        $scope.step = toStep
      else
        $scope.alert = "Cannot proceed to step #{toStep}!"
        console.log $scope.alert







    # $scope.open = (step) ->
    #   modalInstance = $modal.open
    #     animation: 1
    #     templateUrl: "templates/mlsOne.jade"
    #     resolve:
    #       data: () ->
    #         return $scope.data

    #   modalInstance.result.then \
    #     ((selectedItem) ->
    #       $scope.selected = selectedItem),
    #     (() ->
    #       console.log "#### dismissed ")
]

