d3 = require 'd3'
pieUtil = require './styles/util.style.piechart.coffee'

serializeXmlNode = (xmlNode) ->
  if window.XMLSerializer?
    return (new window.XMLSerializer()).serializeToString(xmlNode)
  if xmlNode.xml?
    return xmlNode.xml
  return ""

formatPieData = (data) ->
  d3.nest()
  .key (k) ->
    k.options.rm_status
  .sortKeys(d3.descending)
  .entries data, d3.map  

pieCreateFunction = (cluster) ->
  children = cluster.getAllChildMarkers()
  c = children.length
  data = formatPieData(children)


  strokewidth = pieUtil.strokewidth
  r = pieUtil.radius
  rinner = pieUtil.innerRadius
  w = (r+1)*2
  h = w

  donut = d3.layout.pie()
  arc = d3.svg.arc().outerRadius(r).innerRadius(rinner)
  svg = document.createElementNS(d3.ns.prefix.svg, 'svg')
  vis = d3.select(svg)
    .data([data])
    .attr('class', 'pieClass')
    .attr('width', w+(2*strokewidth))
    .attr('height', h*(2*strokewidth))

  vis.append('circle')
    .attr('cx', r)
    .attr('cy', r)
    .attr('r', r)
    .attr('fill', 'white')

  arcs = vis.selectAll('g.arc')
    .data(donut.value(pieUtil.valueFunc))
    .enter().append('svg:g')
    .attr('class', 'arc')
    .attr('transform', 'translate('+r+','+r+')')

  arcs.append('svg:path')
    .attr('class', pieUtil.pathClassFunc)
    .attr('stroke-width', strokewidth)
    .attr('d', arc)
    .append('svg:title')
    .text(pieUtil.pathTitleFunc)

  vis.append('text')
    .attr('x', r)
    .attr('y', r)
    .attr('class', 'marker-cluster-pie-label')
    .attr('text-anchor', 'middle')
    .attr('dy', '.4em')
    .attr('fill', 'black')
    .text(c)

  html = serializeXmlNode(svg)
  return new L.DivIcon({ html: html });



module.exports =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: "markercluster"
    visible: true
    layerOptions:
      maxClusterRadius: 100
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true
      iconCreateFunction: pieCreateFunction

  backendPriceCluster:
    name: 'Price Cluster'
    type: 'group'
    visible: true

  addresses:
    name: 'Addresses'
    type: 'group'
    visible: true
