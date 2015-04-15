require '../../../common/extensions/strings.coffee'

describe "extensions > String".ourNs().ourNs('Common'), ->
  describe 'contains', ->
    it 'finds words', ->
      'wow specs rule'.contains('rule').should.be.ok
    it 'does not finds words', ->
      'wow specs rule'.contains('sucks').should.not.be.ok

  describe 'ourNs', ->
    it 'defaults to ', ->
      ''.ourNs().should.be.eql 'rmaps'

    it 'can be overriden', ->
      ''.ourNs('test').should.not.be.eql 'test\--'