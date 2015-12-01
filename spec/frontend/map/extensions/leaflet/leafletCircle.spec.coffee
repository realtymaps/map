describe 'leafletCircle extensions', ->
  beforeEach ->
    @subject = new L.Circle  L.latLng(50.5, 30.5), 20

  it 'toGeoJSON', ->
    feat = @subject.toGeoJSON()
    # console.log feat
    feat.properties.shape_extras.type.should.be.eql 'Circle'
    feat.properties.shape_extras.radius.should.be.eql @subject.getRadius()
