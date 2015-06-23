app = require '../app.coffee'

app.factory 'validatorBuilder', () ->

  _getValidationString = (type, vOptions) ->
    vOptionsStr = JSON.stringify(vOptions)
    "validation.#{type}(#{vOptionsStr})"


  getTransform = (options) ->
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
    transform = null
    switch options.baseName
      when 'address'
        transform = _getValidationString('address', options.vOptions)
      else
        transform = _getValidationString(options.type, options.vOptions)

    transform
