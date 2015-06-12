app = require '../app.coffee'

app.factory 'validatorBuilder', () ->

  _getOptionsString = (vOptions) ->
    # placeholder function for when we have to handle nested validations
    # could be recursive if that makes sense
    # returns regular json string if it's simple
    #
    # vOptions:
    #   key-value pairs to deliver as arguments to validation

    # handle primitave types
    if _.every(_.values(vOptions), (v) -> typeof v != 'object')
      JSON.stringify(vOptions)


  _getValidationString = (type, vOptions) ->
    vOptionsStr = getOptionsString(vOptions);
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
    _getValidationString(options.type, options.vOptions)
