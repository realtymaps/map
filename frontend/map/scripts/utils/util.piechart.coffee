d3 = require 'd3'
pieStyl = require './styles/util.style.piechart.coffee'

serializeXmlNode = (xmlNode) ->
  if window.XMLSerializer?
    return (new window.XMLSerializer()).serializeToString(xmlNode)
  if xmlNode.xml?
    return xmlNode.xml
  return ""

# massage data for better usage in pie arcs
# there's an opportunity to simplify(reduce) the returned dataset to facilitate
#  optimization and minimum-arc-size
formatPieData = (data) ->
  d3.nest()
  .key (k) ->
    k.options.rm_status
  .sortValues (v) ->
    v.length
  .entries data, d3.map

formatPieDataBackend = (cluster) ->
  return [
    {key: "pending", values: {"length": cluster.pending}}, # feign 'length' attribute of array
    {key: "for sale", values: {"length": cluster.forsale}},
    {key: "recently sold", values: {"length": cluster.recentlysold}},
    {key: "not for sale", values: {"length": cluster.notforsale}}
  ]

makeSvg = (data, total) ->
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

  # white circle for background behind cluster number in pie (css background does not work)
  vis.append('circle')
    .attr('cx', pieStyl.radius)
    .attr('cy', pieStyl.radius)
    .attr('r', pieStyl.radius)
    .attr('fill', 'white')

  # arc data according to the parcel counts in dataset
  arcs = vis.selectAll('g.arc')
    .data(donut.value(pieStyl.valueFunc(total)))
    .enter().append('svg:g')
    .attr('class', 'arc')
    .attr('transform', 'translate('+(pieStyl.radius+pieStyl.arcOffset)+','+(pieStyl.radius+pieStyl.arcOffset)+')')

  # visuals & styling for the arcs
  arcs.append('svg:path')
    .attr('class', pieStyl.pathClassFunc)
    .attr('stroke-width', pieStyl.strokewidth)
    .attr('d', arc)
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

# designed for usage as leaflet 'iconCreateFunction'
pieCreateFunction = (cluster) ->
  children = cluster.getAllChildMarkers()
  data = formatPieData(children)
  html = serializeXmlNode(makeSvg(data, children.length))
  return new L.DivIcon
    html: html

pieCreateFunctionBackend = (cluster) ->
  data = formatPieDataBackend(cluster)
  return serializeXmlNode(makeSvg(data, cluster.count))


module.exports = 
  pieCreateFunction: pieCreateFunction
  pieCreateFunctionBackend: pieCreateFunctionBackend
