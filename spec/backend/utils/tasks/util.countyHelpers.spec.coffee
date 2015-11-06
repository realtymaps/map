basePath = require '../../basePath'
rewire = require 'rewire'
countyHelpers = rewire "#{basePath}/utils/tasks/util.countyHelpers"
_listExtend = countyHelpers.__get__('_listExtend')

describe 'countyHelpers', () ->
  describe '_listExtend', () ->
    it 'should merge 2 specially-formatted lists', () ->
      list1 = [
        name: 'item1'
        value: 'list1-value1'
      ,
        name: 'item2'
        value: 'list1-value2'
      ,
        name: 'item3'
        value: 'list1-value3'
      ,
        name: 'item5'
        value: 'list1-value5'
      ,
        name: 'item9'
        value: 'list1-value9'
      ,
        name: 'item10'
        value: 'list1-value10'
      ]
      list2 = [
        name: 'item1'
        value: 'list2-value1'
      ,
        name: 'item3'
        value: 'list2-value3'
      ,
        name: 'item4'
        value: 'list2-value4'
      ,
        name: 'item5'
        value: 'list2-value5'
      ,
        name: 'item6'
        value: 'list2-value6'
      ,
        name: 'item7'
        value: 'list2-value7'
      ,
        name: 'item8'
        value: 'list2-value8'
      ]
      expected = [
        name: 'item1'
        value: 'list1-value1'
      ,
        name: 'item2'
        value: 'list1-value2'
      ,
        name: 'item3'
        value: 'list1-value3'
      ,
        name: 'item4'
        value: 'list2-value4'
      ,
        name: 'item5'
        value: 'list1-value5'
      ,
        name: 'item6'
        value: 'list2-value6'
      ,
        name: 'item7'
        value: 'list2-value7'
      ,
        name: 'item8'
        value: 'list2-value8'
      ,
        name: 'item9'
        value: 'list1-value9'
      ,
        name: 'item10'
        value: 'list1-value10'
      ]
      _listExtend(list1, list2)
      list1.should.eql(expected)
