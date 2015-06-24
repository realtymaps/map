app = require '../app.coffee'
_ = require 'lodash'

app.service 'validatorBuilder', () ->

  _getValidationString = (type, vOptions) ->
    vOptionsStr = if vOptions then JSON.stringify(vOptions) else ''
    "validation.#{type}(#{vOptionsStr})"

  lookupType = (field) ->
    types =
      Int:
        name: 'integer'
        label: 'Number'
      Decimal:
        name: 'float'
        label: 'Number'
      Long:
        name: 'float'
        label: 'Number'
      Character:
        name: 'string'
      DateTime:
        name: 'datetime'
        label: 'Date and Time'
      Boolean:
        name: 'boolean'
        label: 'Yes/No'

    type = types[field.DataType]

    if type?.name == 'string'
      if field.Interpretation == 'Lookup'
        type.label = 'Restricted Text (single value)'
      else if field.Interpretation == 'LookupMulti'
        type.label = 'Restricted Text (multiple values)'
      else
        type.label = 'User-Entered Text'

    type

  getTransform = (field) ->
    #   options:
    #
    #     type: integer | float | string | fips | choice | currency | ...
    #       Maps to a validation handler.
    #       EG if type = "integer", we will expect:
    #       "validation.integer"
    #       If in future these seem arcane, like "rm_property_id",
    #         we can create a map
    #     vOptions:
    #       validation options to be nested into validation calls
    #     choices:
    #       key-value mapping for choice field
    #       present if type is choices
    #

    vOptions = _.pick field.config, (v) -> v?
    choices = vOptions.choices || {}
    type = lookupType(field)?.name

    switch field.output
      when 'address'
        _getValidationString('address')

      when 'status', 'substatus', 'status_display'
        _getValidationString('choices', choices)

      else
        _getValidationString(type, vOptions)

  lookupType: lookupType
  getTransform: getTransform
