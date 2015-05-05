
describe 'Karma Sanity'.ourNs().ourNs('FrontEnd'), ->
  describe 'fixtures', ->

    it 'should exist', ->
      fixture.should.be.ok

    it 'load exist', ->
      fixture.load.should.be.ok

    it 'el exists', ->
      fixture.el.should.be.ok

    it 'json exists', ->
      fixture.json.should.be.ok
