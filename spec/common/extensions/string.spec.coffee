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

  it 'space', ->
    ''.space().should.be.eql ' '

  describe 'orNA', ->
    it 'empty', ->
      String.orNA().should.be.eql 'N/A'

    it 'not empty', ->
      String.orNA('crap').should.be.eql 'crap'

  describe 'orDash', ->
    it 'empty', ->
      String.orDash().should.be.eql '-'

    it 'not empty', ->
      String.orDash('crap').should.be.eql 'crap'

  describe 'toInitCaps', ->
    it 'single word', ->
      'crap'.toInitCaps().should.be.eql 'Crap'

    it 'two words', ->
      'crap beer'.toInitCaps().should.be.eql 'Crap Beer'

  describe 'replaceLast', ->
    it 'last word', ->
      'redonkulous poopy poopy beer'.replaceLast('poopy', 'yummy').should.be.eql 'redonkulous poopy yummy beer'

  describe 'startsWith', ->
    it 'has last', ->
      'redonkulous poopy poopy beer'.startsWith('redonkulous').should.be.ok

    it 'does not have last', ->
      'redonkulous poopy poopy beer'.startsWith('beers').should.not.be.ok

  describe 'endsWith', ->
    it 'has last', ->
      'redonkulous poopy poopy beer'.endsWith('beer').should.be.ok

    it 'does not have last', ->
      'redonkulous poopy poopy beer'.endsWith('beers').should.not.be.ok

  describe 'firstRest', ->
    it 'has both', ->
      firstRest = 'req.user.id'.firstRest('.')
      firstRest.first.should.be.ok
      firstRest.first.should.be.eql 'req'
      firstRest.rest.should.be.ok
      firstRest.rest.should.be.eql 'user.id'

    it 'has none', ->
      firstRest = ''.firstRest('.')
      firstRest.first.should.be.ok
      firstRest.first.should.be.eql ''
      expect(firstRest.rest).to.not.be.ok
