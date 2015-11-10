describe 'leafletCircle extensions', ->
  beforeEach ->
    @subject = new L.Circle  L.latLng(50.5, 30.5), 20

  it 'toGeoJSON', ->
    feat = @subject.toGeoJSON()
    # console.log feat
    feat.properties.shapeType.should.be.eql 'Circle'
    feat.properties.radius.should.be.eql @subject.getRadius()
