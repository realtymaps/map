basePath = require '../basePath'

subject = require "#{basePath}/utils/util.sql.strings"

describe 'util.sql.strings', ->
  it 'exists', ->
    subject.should.be.ok

  it 'selectAll is correct', ->
    subject.SELECTAll.should.be.eql """select *
    from %s
    where
    """.space()

