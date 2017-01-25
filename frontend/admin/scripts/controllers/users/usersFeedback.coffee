app = require '../../app.coffee'
gridCellView = require '../../../../common/html/views/templates/gridCellView.jade'
moment = require 'moment'


app.controller 'rmapsUsersFeedbackCtrl', (
  $q
  $uibModal
  Restangular
  rmapsUsersService
  rmapsGridFactory
  rmapsUserFeedbackService
  rmapsUserFeedbackCategoryService
  rmapsUserFeedbackSubcategoryService
  uiGridConstants
  $scope
) ->

  $scope.getData = rmapsUserFeedbackService.get

  $scope.gridName = 'User Feedback'

  $q.all({
    categories: rmapsUserFeedbackCategoryService.get()
    subcategories: rmapsUserFeedbackSubcategoryService.get()
  }).then (resolves) ->

    $scope.ready = true

    hashes =
      categories: {}
      subcategories: {}
    filterOptions = {
      categories: []
      subcategories: []
    }

    for category in resolves.categories
      hashes.categories[category.id] = category.name
      filterOptions.categories.push(value: category.id, label: category.name)
    for subcategory in resolves.subcategories
      hashes.subcategories[subcategory.id] = subcategory.name
      filterOptions.subcategories.push(value: subcategory.id, label: "[#{hashes.categories[subcategory.category]}] #{subcategory.name}")

    new rmapsGridFactory $scope,
      filters: {}
      enableFiltering: true
      paginationPageSizes: [10, 25, 50, 75],
      paginationPageSize: 25,
      columnDefs: [
        field: 'auth_user_email'
        displayName: 'Email'
        width: 250
        enableCellEdit: false
        pinnedLeft: true
      ,
        field: "category"
        displayName: 'Category'
        width: 250
        enableCellEdit: false
        filter: { selectOptions: filterOptions.categories, type: uiGridConstants.filter.SELECT }
        cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
        getCellView: (code) -> hashes.categories[code]
      ,
        field: "subcategory"
        displayName: 'Subcategory'
        width: 250
        enableCellEdit: false
        filter: { selectOptions: filterOptions.subcategories, type: uiGridConstants.filter.SELECT }
        cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
        getCellView: (code) -> hashes.subcategories[code]
      ,
        field: "description"
        displayName: 'Description'
        width: 500
        type:'string'
        enableCellEdit: false
        cellTooltip: true
      ,
        field: "rm_inserted_time"
        displayName: 'Timestamp'
        width: 200
        type:'date'
        enableCellEdit: false
        cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
        getCellView: (date) -> moment.utc(date, 'YYYY-MM-DD[T]HH:mm:ss.SSSZ').utcOffset((new Date()).getTimezoneOffset()/-60).format('YYYY-MM-DD[ at ]HH:mm:ss')
      ]
