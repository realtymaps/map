mod = require '../module.coffee'
Case = require 'case'
_ = require 'lodash'

mod.directive 'validatorDrop', (
$validation
$parse
$log) ->
  $log = $log.spawn('validatorDrop')

  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    oldValidators = {}

    if !attrs.validatorDrop
      dropAll = true
    else
      dropFields = attrs.validatorDrop.split(',')


    dropField = (field, doDrop) ->
      field = Case.camel(field)
      if ngModel.$validators?[field]? && doDrop
        oldValidators[field] = ngModel.$validators[field]
        ngModel.$validators[field] = () -> true
      else if oldValidators[field]? #revert
        ngModel.$validators[field] = oldValidators[field]

    dropAngularValidatorField = (field, doDrop) ->
      if ngModel.$angularValidators?[field]? && doDrop
        #save off
        oldValidators[field] = ngModel.$angularValidators[field]
        ngModel.$angularValidators[field] = (index) ->
          oldValidators[field](index, true) #true is override
      else if oldValidators[field]? #revert
        ngModel.$angularValidators[field] = oldValidators[field]


    scope.$watch attrs.validatorDropIf, (newVal, oldVal) ->
      return if newVal == oldVal

      # handle normal $validators
      # note most of the angular world uses $validators!
      if dropAll
        _.each ngModel.$validators, (v,k) ->
          dropField(k, newVal)

        _.each ngModel.$angularValidators, (v,k) ->
          dropAngularValidatorField(k, newVal)

      else
        dropFields.each (v) ->
          dropField(v, newVal)
          dropAngularValidatorField(v, newVal)

      # if newVal
      #   #so some of the card fields will set $parse to invalid, and then $validators
      #   #wont be called this is attempts to get around that
      #   #basically this is only a problem if you touched a field and entered something and then cleared it
      #   #it will still be invalid as it is required
      #   ngModel.$setPristine()
      #   ngModel.$setUntouched()

      ngModel.$validate()
      return
