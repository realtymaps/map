require '../../../common/extensions/strings.coffee'

describe "extensions > String".ns().ns('Common'), ->
  describe 'contains', ->
    it 'finds words', ->
      'wow specs rule'.contains('rule').should.be.ok
    it 'does not finds words', ->
      'wow specs rule'.contains('sucks').should.not.be.ok

  describe 'ns', ->
    it 'defaults to ', ->
      ''.ns().should.be.eql 'rmaps'

    it 'can be overriden', ->
      ''.ns('test').should.not.be.eql 'test\--'