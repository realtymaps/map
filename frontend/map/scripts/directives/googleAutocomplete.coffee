app = require '../app.coffee'
_ = require 'lodash'



app.directive 'rmapsGoogleAutocomplete', ($parse, $compile, $timeout, $document, $log, rmapsGoogleService) ->
  $log = $log.spawn 'rmapsGoogleAutocomplete'

  restrict: 'A'
  require: '^ngModel'
  scope:
    model: '=ngModel'
    options: '=?'
    forceSelection: '=?'
    customPlaces: '=?'
  controller: [
    '$scope'
    ($scope) ->
  ]
  link: ($scope, element, attrs, controller) ->
    keymap =
      tab: 9
      enter: 13
      esc: 27
      up: 38
      down: 40
    hotkeys = [
      keymap.tab
      keymap.enter
      keymap.esc
      keymap.up
      keymap.down
    ]
    rmapsGoogleService.getAPI().then (gmaps) ->
      autocompleteService = new (google.maps.places.AutocompleteService)
      placesService = new (google.maps.places.PlacesService)(element[0])

      initEvents = ->
        element.bind 'keydown', onKeydown
        element.bind 'blur', ->
          clearPredictions()
        element.bind 'submit', onBlur
        $scope.$watch 'selected', select
        return

      initAutocompleteDrawer = ->
        # Drawer element used to display predictions
        drawerElement = angular.element('<div rmaps-google-autocomplete-drawer></div>')
        body = angular.element($document[0].body)
        $drawer = undefined
        drawerElement.attr
          input: 'input'
          query: 'query'
          predictions: 'predictions'
          active: 'active'
          selected: 'selected'
        $drawer = $compile(drawerElement)($scope)
        body.append $drawer
        # Append to DOM
        $scope.$on '$destroy', ->
          $drawer.remove()
          return
        return

      initNgModelController = ->
        controller.$parsers.push parse
        controller.$formatters.push format
        controller.$render = render
        return

      onKeydown = (event) ->
        if $scope.predictions.length == 0 or indexOf(hotkeys, event.which) == -1
          return
        event.preventDefault()
        if event.which == keymap.down
          $scope.active = ($scope.active + 1) % $scope.predictions.length
          $scope.$digest()
        else if event.which == keymap.up
          $scope.active = (if $scope.active then $scope.active else $scope.predictions.length) - 1
          $scope.$digest()
        else if event.which == 13 or event.which == 9
          if $scope.forceSelection
            $scope.active = if $scope.active == -1 then 0 else $scope.active
          $scope.$apply ->
            $scope.selected = $scope.active
            if $scope.selected == -1
              clearPredictions()
            return
        else if event.which == 27
          $scope.$apply ->
            event.stopPropagation()
            clearPredictions()
            return
        return

      onBlur = (event) ->
        if $scope.predictions.length == 0
          return
        if $scope.forceSelection
          $scope.selected = if $scope.selected == -1 then 0 else $scope.selected
        $scope.$digest()
        $scope.$apply ->
          if $scope.selected == -1
            clearPredictions()
          return
        return

      select = ->
        prediction = undefined
        prediction = $scope.predictions[$scope.selected]
        if !prediction
          return
        if prediction.is_custom
          $scope.$apply ->
            $scope.model = prediction.place
            $scope.$emit 'g-places-autocomplete:select', prediction.place
            $timeout ->
              controller.$viewChangeListeners.forEach (fn) ->
                fn()
                return
              return
            return
        else
          placesService.getDetails { placeId: prediction.place_id }, (place, status) ->
            if status == google.maps.places.PlacesServiceStatus.OK
              $scope.$apply ->
                $scope.model = place
                $scope.$emit 'g-places-autocomplete:select', place
                $timeout ->
                  controller.$viewChangeListeners.forEach (fn) ->
                    fn()
                    return
                  return
                return
            return
        clearPredictions()
        return

      parse = (viewValue) ->
        request = undefined
        if !(viewValue and isString(viewValue))
          return viewValue
        $scope.query = viewValue
        request = angular.extend({ input: viewValue }, $scope.options)
        autocompleteService.getPlacePredictions request, (predictions, status) ->
          $scope.$apply ->
            customPlacePredictions = undefined
            clearPredictions()
            if $scope.customPlaces
              customPlacePredictions = getCustomPlacePredictions($scope.query)
              $scope.predictions.push.apply $scope.predictions, customPlacePredictions
            if status == google.maps.places.PlacesServiceStatus.OK
              $scope.predictions.push.apply $scope.predictions, predictions
            if $scope.predictions.length > 5
              $scope.predictions.length = 5
              # trim predictions down to size
            return
          return
        if $scope.forceSelection
          controller.$modelValue
        else
          viewValue

      format = (modelValue) ->
        viewValue = ''
        if isString(modelValue)
          viewValue = modelValue
        else if isObject(modelValue)
          viewValue = modelValue.formatted_address
        viewValue

      render = ->
        element.val controller.$viewValue

      clearPredictions = ->
        $scope.active = -1
        $scope.selected = -1
        $scope.predictions = []
        return

      getCustomPlacePredictions = (query) ->
        predictions = []
        place = undefined
        match = undefined
        i = undefined
        i = 0
        while i < $scope.customPlaces.length
          place = $scope.customPlaces[i]
          match = getCustomPlaceMatches(query, place)
          if match.matched_substrings.length > 0
            predictions.push
              is_custom: true
              custom_prediction_label: place.custom_prediction_label or '(Custom Non-Google Result)'
              description: place.formatted_address
              place: place
              matched_substrings: match.matched_substrings
              terms: match.terms
          i++
        predictions

      getCustomPlaceMatches = (query, place) ->
        q = query + ''
        terms = []
        matched_substrings = []
        fragment = undefined
        termFragments = undefined
        i = undefined
        termFragments = place.formatted_address.split(',')
        i = 0
        while i < termFragments.length
          fragment = termFragments[i].trim()
          if q.length > 0
            if fragment.length >= q.length
              if startsWith(fragment, q)
                matched_substrings.push
                  length: q.length
                  offset: i
              q = ''
              # no more matching to do
            else
              if startsWith(q, fragment)
                matched_substrings.push
                  length: fragment.length
                  offset: i
                q = q.replace(fragment, '').trim()
              else
                q = ''
                # no more matching to do
          terms.push
            value: fragment
            offset: place.formatted_address.indexOf(fragment)
          i++
        {
          matched_substrings: matched_substrings
          terms: terms
        }

      isString = (val) ->
        Object::toString.call(val) == '[object String]'

      isObject = (val) ->
        Object::toString.call(val) == '[object Object]'

      indexOf = (array, item) ->
        i = undefined
        length = undefined
        if array == null
          return -1
        length = array.length
        i = 0
        while i < length
          if array[i] == item
            return i
          i++
        -1

      startsWith = (string1, string2) ->
        toLower(string1).lastIndexOf(toLower(string2), 0) == 0

      toLower = (string) ->
        if string == null then '' else string.toLowerCase()

      (->
        $scope.query = ''
        $scope.predictions = []
        $scope.input = element
        $scope.options = $scope.options or {}
        initAutocompleteDrawer()
        initEvents()
        initNgModelController()
        return
      )()
      return

app.directive 'rmapsGoogleAutocompleteDrawer', ($window, $document) ->
  TEMPLATE = [
    '<div class="pac-container" ng-if="isOpen()" ng-style="{top: position.top+\'px\', left: position.left+\'px\', width: position.width+\'px\'}" style="display: block;" role="listbox" aria-hidden="{{!isOpen()}}">'
    '  <div class="pac-item" g-places-autocomplete-prediction index="$index" prediction="prediction" query="query"'
    '       ng-repeat="prediction in predictions track by $index" ng-class="{\'pac-item-selected\': isActive($index) }"'
    '       ng-mouseenter="selectActive($index)" ng-click="selectPrediction($index)" role="option" id="{{prediction.id}}">'
    '  </div>'
    '</div>'
  ]

  restrict: 'A'
  scope:
    input: '='
    query: '='
    predictions: '='
    active: '='
    selected: '='
  template: TEMPLATE.join('')
  link: ($scope, element) ->

    getDrawerPosition = (element) ->
      domEl = element[0]
      rect = domEl.getBoundingClientRect()
      docEl = $document[0].documentElement
      body = $document[0].body
      scrollTop = $window.pageYOffset or docEl.scrollTop or body.scrollTop
      scrollLeft = $window.pageXOffset or docEl.scrollLeft or body.scrollLeft
      {
        width: rect.width
        height: rect.height
        top: rect.top + rect.height + scrollTop
        left: rect.left + scrollLeft
      }

    element.bind 'mousedown', (event) ->
      event.preventDefault()
      # prevent blur event from firing when clicking selection
      return

    $window.onresize = ->
      $scope.$apply ->
        $scope.position = getDrawerPosition($scope.input)
        return
      return

    $scope.isOpen = ->
      $scope.predictions.length > 0

    $scope.isActive = (index) ->
      $scope.active == index

    $scope.selectActive = (index) ->
      $scope.active = index
      return

    $scope.selectPrediction = (index) ->
      $scope.selected = index
      return

    $scope.$watch 'predictions', (->
      $scope.position = getDrawerPosition($scope.input)
      return
    ), true
    return

app.directive 'gPlacesAutocompletePrediction', ->
  TEMPLATE = [
    '<span class="pac-icon pac-icon-marker"></span>'
    '<span class="pac-item-query" ng-bind-html="prediction | highlightMatched"></span>'
    '<span ng-repeat="term in prediction.terms | unmatchedTermsOnly:prediction">{{term.value | trailingComma:!$last}}&nbsp;</span>'
    '<span class="custom-prediction-label" ng-if="prediction.is_custom">&nbsp;{{prediction.custom_prediction_label}}</span>'
  ]

  restrict: 'A'
  scope:
    index: '='
    prediction: '='
    query: '='
  template: TEMPLATE.join('')

app.filter 'highlightMatched', ($sce) ->
  (prediction) ->
    matchedPortion = ''
    unmatchedPortion = ''
    matched = undefined
    if prediction.matched_substrings.length > 0 and prediction.terms.length > 0
      matched = prediction.matched_substrings[0]
      matchedPortion = prediction.terms[0].value.substr(matched.offset, matched.length)
      unmatchedPortion = prediction.terms[0].value.substr(matched.offset + matched.length)
    $sce.trustAsHtml '<span class="pac-matched">' + matchedPortion + '</span>' + unmatchedPortion

app.filter 'unmatchedTermsOnly', ->
  (terms, prediction) ->
    i = undefined
    term = undefined
    filtered = []
    i = 0
    while i < terms.length
      term = terms[i]
      if prediction.matched_substrings.length > 0 and term.offset > prediction.matched_substrings[0].length
        filtered.push term
      i++
    filtered

app.filter 'trailingComma', ->
  (input, condition) ->
    if condition then input + ',' else input
