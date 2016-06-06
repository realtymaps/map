require("chai").should()
logger = require('../../specUtils/logger').spawn('validation')
{basePath} = require '../globalSetup'
rewire = require('rewire')
dataLoadHelpers = rewire("#{basePath}/tasks/util.dataLoadHelpers")

_diff = dataLoadHelpers.__get__('_diff')
_flattenRow = dataLoadHelpers.__get__('_flattenRow')

describe 'util.dataLoadHelpers', () ->

  describe '_diff', () ->

    it 'returns an object with changed fields and the old values', () ->
      oldObj =
        num_same: 1
        num_diff: 2
        str_same: "aaaaa"
        str_diff: "bbbbb"
        obj_same: {a: 1}
        obj_diff: {b: 2}
      newObj =
        num_same: 1
        num_diff: 3
        str_same: "aaaaa"
        str_diff: "ccccc"
        obj_same: {a: 1}
        obj_diff: {c: 3}
      changes = _diff(newObj, oldObj)
      changes.should.deep.equal
        num_diff: 2
        str_diff: "bbbbb"
        obj_diff: {b: 2}

    it 'returns an object with deleted fields and the old values', () ->
      oldObj =
        num_same: 1
        num_del: 2
        str_same: "aaaaa"
        str_del: "bbbbb"
        obj_same: {a: 1}
        obj_del: {b: 2}
      newObj =
        num_same: 1
        str_same: "aaaaa"
        obj_same: {a: 1}
      changes = _diff(newObj, oldObj)
      changes.should.deep.equal
        num_del: 2
        str_del: "bbbbb"
        obj_del: {b: 2}

    it 'returns an object with added fields and null values', () ->
      oldObj =
        num_same: 1
        str_same: "aaaaa"
        obj_same: {a: 1}
      newObj =
        num_same: 1
        num_add: 2
        str_same: "aaaaa"
        str_add: "bbbbb"
        obj_same: {a: 1}
        obj_add: {b: 2}
      changes = _diff(newObj, oldObj)
      changes.should.deep.equal
        num_add: null
        str_add: null
        obj_add: null

    it 'does all 3 together', () ->
      oldObj =
        num_same: 1
        num_diff: 2
        str_same: "aaaaa"
        str_del: "bbbbb"
        obj_same: {a: 1}
      newObj =
        num_same: 1
        num_diff: 3
        str_same: "aaaaa"
        obj_same: {a: 1}
        obj_add: {b: 2}
      changes = _diff(newObj, oldObj)
      changes.should.deep.equal
        num_diff: 2
        str_del: "bbbbb"
        obj_add: null


  describe '_flattenRow', () ->
    reverts = []

    before () ->
      fakeValidatorBuilder =
        getBaseRules: (dataSourceType, dataType) ->
          rules =
            test:
              type1:
                base1: {}
                base2: {}
          return rules[dataSourceType][dataType]
      reverts.push(dataLoadHelpers.__set__('validatorBuilder', fakeValidatorBuilder))

    after () ->
      for revert in reverts
        revert()

    it 'flattens name-value lists from shared_groups and subscriber_groups', () ->
      row =
        shared_groups:
          group1: [
            {name: 'a', value: 1}
            {name: 'b', value: 2}
          ]
          group2: [
            {name: 'c', value: 3}
            {name: 'd', value: 4}
          ]
        subscriber_groups:
          group3: [
            {name: 'e', value: 5}
            {name: 'f', value: 6}
          ]
          group4: [
            {name: 'g', value: 7}
            {name: 'h', value: 8}
          ]
      flattened = _flattenRow(row, 'test', 'type1')
      flattened.should.deep.equal(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8)

    it 'merges in hidden and ungrouped fields', () ->
      row =
        hidden_fields:
          i: 11
          j: 12
        ungrouped_fields:
          k: 13
          l: 14
      flattened = _flattenRow(row, 'test', 'type1')
      flattened.should.deep.equal(i: 11, j: 12, k: 13, l: 14)

    it 'retains base/filter fields as configured by validatorBuilder', () ->
      row =
        base1: 21
        base2: 22
        base3: 23
        base4: 24
      flattened = _flattenRow(row, 'test', 'type1')
      flattened.should.deep.equal(base1: 21, base2: 22)

    it 'does all 3', () ->
      row =
        shared_groups:
          group1: [
            {name: 'a', value: 1}
            {name: 'b', value: 2}
          ]
        hidden_fields:
          i: 11
          j: 12
        base1: 21
        base4: 24
      flattened = _flattenRow(row, 'test', 'type1')
      flattened.should.deep.equal(a: 1, b: 2, i: 11, j: 12, base1: 21)


  describe 'buildUniqueSubtaskName', () ->
    it 'should build the correct subid string', () ->
      subid = null
      expectedSubid = 'abcde_digimaps_parcel_1234'
      subid = dataLoadHelpers.buildUniqueSubtaskName
        batch_id: 'abcde'
        task_name: 'digimaps'
        data:
          deletes: dataLoadHelpers.DELETE.UNTOUCHED
          dataType: "normParcel"
          rawDataType: "parcel"
          rawTableSuffix: '1234'
          subset:
            fips_code: '1234'
      subid.should.be.eql expectedSubid
