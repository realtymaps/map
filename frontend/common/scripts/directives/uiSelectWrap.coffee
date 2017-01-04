mod = require '../module.coffee'

mod.directive 'uiSelectWrap', ($document, uiGridEditConstants) ->
  restrict: 'E'
  #https://plnkr.co/edit/m6IeX7FQbe4CvFYuAmzj?p=info
  link: ($scope, $elm, $attr) -> #link
    docClick = ({target}) ->
      if !target.closest('.ui-select-container')?
        $scope.$emit(uiGridEditConstants.events.END_CELL_EDIT)
        $document.off('mousedown', docClick)

    $document.on('mousedown', docClick)

    return
