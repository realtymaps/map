_ = require 'lodash'
{validators} = require '../util.validation'


state =
  state: [
    validators.object
      subValidateSeparate:
        account_image_id: validators.integer()
        filters: validators.object()
        map_toggles: validators.object()
        map_position: validators.object()
        map_results: [validators.object(), validators.defaults(defaultValue: {})]
        auth_user_id: validators.integer()
        parent_auth_user_id: validators.integer()
    validators.defaults(defaultValue: {})
  ]

body = _.extend {}, state,
  bounds: validators.string()
  returnType: validators.string()
  columns: validators.string()
  isArea: validators.boolean(truthy: true, falsy: false)
  pins: validators.object()
  geometry_center: validators.object()
  rm_property_id: transform: any: [validators.string(minLength:1), validators.array()]


save =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    rm_property_id: validators.string(minLength:1)

module.exports = {
  state
  body
  save
}
