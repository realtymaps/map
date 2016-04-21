{validators, requireAllTransforms, notRequired} = require '../util.validation'

module.exports =
  getResized:
    params: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
    query:  validators.object subValidateSeparate: requireAllTransforms
      data_source_id: validators.string(minLength: 2)
      data_source_uuid: validators.string(minLength: 2)
      photo_id: notRequired validators.string(minLength: 1)
      image_id: validators.integer()
      width: notRequired validators.integer()
      height: notRequired validators.integer()
