app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

app.controller 'rmapsMlsCtrl', [ '$scope', '$state',
  ($scope, $state) ->
    $scope.mock =
      db: ['dbOne', 'dbTwo']
      table: ['tableOne', 'tableTwo']
      field: ['fieldOne', 'fieldTwo']

    $scope.oneAtATime = false

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

    $scope.formItems = [
      step: 0
      heading: "Log into MLS"
      formFields:         
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
      proceed: () ->
        console.log "#### proceeding step 0"
      disabled: false
    ,
      step: 1
      heading: "Select Database..."
      formFields:
        db:
          type: "select"
          label: "Database"
          options:
            one: "db1"
            two: "db2"
            three: "db3"
            four: "db4"
      proceed: () ->
        console.log "#### proceeding step 1"
      disabled: true
    ,
      step: 2
      heading: "Select Table..."
      formFields:
        table:
          type: "select"
          label: "Table"
          options:
            one: "table1"
            two: "table2"
      proceed: () ->
        console.log "#### proceeding step 2"
      disabled: true
    ,
      step: 3
      heading: "Select Field..."
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
      proceed: () ->
        console.log "#### proceeding step 3"
      disabled: true
    ]

    $scope.proceed = (step) ->
      $scope.formItems[step].proceed()
      if (step == ($scope.formItems.length-1))
        $scope.step = 0
      else
        $scope.step += 1





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

