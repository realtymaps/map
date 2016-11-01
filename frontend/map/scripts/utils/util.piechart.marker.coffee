d3 = require 'd3'
pieStyl = require './styles/util.style.piechart.coffee'
L = require 'leaflet'

_serializeXmlNode = (xmlNode) ->
  if window.XMLSerializer?
    return (new window.XMLSerializer()).serializeToString(xmlNode)
  if xmlNode.xml?
    return xmlNode.xml
  return ''

# massage data for better usage in pie arcs
# there's an opportunity to simplify(reduce) the returned dataset to facilitate
#  optimization and minimum-arc-size
_formatPieData = (data, forceType) ->
  d3.nest()
  .key (k) ->
    forceType || k.status
  .sortValues (v) ->
    v.length
  .entries data, d3.map

_formatPieDataBackend = (cluster) ->
  return [
    {key: 'pending', values: {'length': cluster.pending}}, # feign 'length' attribute of array
    {key: 'for sale', values: {'length': cluster.forsale}},
    {key: 'sold', values: {'length': cluster.sold}},
    {key: 'not for sale', values: {'length': cluster.notforsale}}
    {key: 'saves', values: {'length': cluster.saves}}
  ]

_makeSvg = (data, total, pieClass) ->
  # stage items for processing and creating pie data
  donut = d3.layout.pie()
  arc = d3.svg.arc().outerRadius(pieStyl.radius).innerRadius(pieStyl.innerRadius)
  svg = document.createElementNS(d3.ns.prefix.svg, 'svg')

  # initialize this pie and give it data set
  vis = d3.select(svg)
    .data([data])
    .attr('class', 'pieClass')
    .attr('width', pieStyl.width)
    .attr('height', pieStyl.height)

  if pieClass
    vis = vis.attr('class', pieClass)

  # white circle for background behind cluster number in pie (css background does not work)
  vis.append('circle')
    .attr('cx', pieStyl.radius)
    .attr('cy', pieStyl.radius)
    .attr('r', pieStyl.radius)
    .attr('fill', 'white')

  # arc data according to the parcel counts in dataset
  arcs = vis.selectAll('g.arc')
    .data(donut.value(pieStyl.valueFunc()))
    .enter().append('svg:g')
    .attr('class', 'arc')
    .attr('transform', 'translate('+(pieStyl.radius+pieStyl.arcOffset)+','+(pieStyl.radius+pieStyl.arcOffset)+')')

  # visuals & styling for the arcs
  arcs.append('svg:path')
    .attr('class', pieStyl.pathClassFunc)
    .attr('stroke-width', pieStyl.strokewidth)
    .attr('d', arc)
    .attr('shape-rendering', 'optimizeQuality')
    .append('svg:title')
    .text(pieStyl.pathTitleFunc)

  # cluster number
  vis.append('text')
    .attr('x', pieStyl.radius+pieStyl.arcOffset)
    .attr('y', pieStyl.radius)
    .attr('class', 'marker-cluster-pie-label')
    .attr('text-anchor', 'middle')
    .attr('dy', pieStyl.textyOffset)
    .text(total)
  return svg

_expandGroups = (children) ->
  result = []
  for child in children
    if child.options.grouped
      result.push(child.options.grouped.properties...)
    else
      result.push child.options
  result

# designed for usage as leaflet 'iconCreateFunction'
create = (cluster, forceType) ->
  cluster.saves ?= 0
  children = _expandGroups(cluster.getAllChildMarkers())
  data = _formatPieData(children, forceType)
  return new L.DivIcon
    html: _serializeXmlNode(_makeSvg(data, children.length))

createSaves = (cluster) ->
  create(cluster, 'saves')

createBackend = (cluster, pieClass) ->
  cluster.saves ?= 0
  data = _formatPieDataBackend(cluster)
  return _serializeXmlNode(_makeSvg(data, cluster.count, pieClass))

module.exports = {
  create
  createSaves
  createBackend
}
