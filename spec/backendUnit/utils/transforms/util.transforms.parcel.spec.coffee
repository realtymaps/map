{validateAndTransform, validators} = require '../../../../backend/utils/util.validation'
transforms = require '../../../../backend/utils/transforms/transform.parcel'
{crsFactory} = require '../../../../common/utils/enums/util.enums.map.coord_system'
clone =  require 'clone'
require("chai").should()

geometry = {"type":"Polygon",
"coordinates":[[[-81.82370672798754,26.327849138760023],[-81.82371186572973,26.32820473011737],
[-81.82352930522971,26.328205549696996],[-81.82352416962513,26.327849980729614],
[-81.82370672798754,26.327849138760023]]]}

testObj =
  parcelapn: '556623'
  fips: '12021'
  sthsnum: '620'
  stunitnum: '123'
  geometry: clone geometry


basicFieldsPromise = validateAndTransform testObj, transforms.prepForRmPropertyId

geo = clone geometry
geo.crs = crsFactory()

describe 'transform.parcel', ->

  it 'prepForRmPropertyId', ->

    basicFieldsPromise
    .then (valid) ->

      valid.should.be.eql
        apn: '556623'
        fipsCode: '12021'
        street_address_num: '620'
        street_unit_num: '123'
        geometry: geo

  it 'final', ->
    basicFieldsPromise
    .then (valid) ->
      validateAndTransform valid, transforms.final
    .then (valid) ->

      valid.should.be.eql
        fips_code: '12021'
        rm_property_id: '12021_556623_001'
        data_source_uuid: '556623'
        street_address_num: '620'
        street_unit_num: '123'
        geometry: geo

  it 'validateAndTransform', ->
    transforms.validateAndTransform testObj
    .then (valid) ->
      valid.should.be.eql
        fips_code: '12021'
        rm_property_id: '12021_556623_001'
        data_source_uuid: '556623'
        street_address_num: '620'
        street_unit_num: '123'
        geometry: geo
