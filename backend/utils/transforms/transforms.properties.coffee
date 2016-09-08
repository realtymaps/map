_ = require 'lodash'
{validators} = require '../util.validation'
internals = require './transforms.properties.internals'
{propertyTypes} = require "../../enums/filterPropertyType"
{statuses} = require "../../enums/filterStatuses"

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
  areaId: validators.integer()
  pins: validators.object(isEmptyProtect: true)
  favorites: validators.object(isEmptyProtect: true)
  geometry_center: validators.object()
  rm_property_id: transform: any: [validators.string(minLength:1), validators.array()]

save =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    rm_property_id: validators.string(minLength:1)

detail =
  properties:
    rm_property_id:
      transform: validators.array()
      required: true
  property:
    rm_property_id_or_geometry_center:
      input: ["rm_property_id", "geometry_center"]
      transform: validators.pickFirst()
      required: true

    rm_property_id:
      transform: validators.string(minLength: 1)

    geometry_center:
      transform: [validators.object(), validators.geojson(toCrs: true)]

    columns:
      transform: validators.choice(choices: ['filter', 'address', 'all', 'id'])
      required: true

    no_alert: validators.boolean(truthy: true, falsy: false)

filterSummary =
  state: validators.object
    subValidateSeparate:
      filters: [
        validators.object
          subValidateSeparate: _.extend internals.minMaxFilterValidations,
            ownerName: [validators.string(trim: true), validators.defaults(defaultValue: "")]
            hasOwner: validators.boolean()
            status: [
              validators.array
                subValidateEach: [
                  validators.string(forceLowerCase: true)
                  validators.choice(choices: statuses)
                ]
              validators.defaults(defaultValue: [])
            ]
            address: [
              validators.object()
              validators.defaults(defaultValue: {})
            ]
            propertyType: [
              validators.string()
              validators.choice(choices: propertyTypes)
            ]
            hasImages: validators.boolean(truthy: true, falsy: false)
            soldRange: validators.string()
            yearBuilt: validators.integer()
          validators.defaults(defaultValue: {})
      ]
  bounds:
    transform: [
      validators.string(minLength: 1)
      validators.geohash
      validators.array(minLength: 2)
    ]
    required: true
  returnType: validators.string()

drawnShapes = _.merge {}, filterSummary,
  isArea: validators.boolean(truthy: true, falsy: false)
  areaId: validators.integer()
  bounds: validators.string(null:true)
  project_id: validators.integer()#even though this is set on the backend it is needed so it is not lost in base impl

module.exports = {
  state
  body
  save
  filterSummary
  drawnShapes
  detail
}
