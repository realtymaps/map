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

makeSvg = (data, total) ->
  # reduce some of the variables for readability
  s = pieStyl.strokewidth
  r = pieStyl.radius
  i = pieStyl.innerRadius
  w = pieStyl.width
  h = pieStyl.height
  a = pieStyl.arcOffset
  dy = pieStyl.dy
  cfn = pieStyl.pathClassFunc
  vfn = pieStyl.valueFunc
  tfn = pieStyl.pathTitleFunc

  # stage items for processing and creating pie data
  donut = d3.layout.pie()
  arc = d3.svg.arc().outerRadius(r).innerRadius(i)
  svg = document.createElementNS(d3.ns.prefix.svg, 'svg')

  # initialize this pie and give it data set
  vis = d3.select(svg)
    .data([data])
    .attr('class', 'pieClass')
    .attr('width', w)
    .attr('height', h)

  # white circle for background behind cluster number in pie (css background does not work)
  vis.append('circle')
    .attr('cx', r)
    .attr('cy', r)
    .attr('r', r)
    .attr('fill', 'white')

  # arc data according to the parcel counts in dataset
  arcs = vis.selectAll('g.arc')
    .data(donut.value(vfn(total)))
    .enter().append('svg:g')
    .attr('class', 'arc')
    .attr('transform', 'translate('+(r+a)+','+(r+a)+')')

  # visuals & styling for the arcs
  arcs.append('svg:path')
    .attr('class', cfn)
    .attr('stroke-width', s)
    .attr('d', arc)
    .append('svg:title')
    .text(tfn)

  # cluster number
  vis.append('text')
    .attr('x', r+a)
    .attr('y', r)
    .attr('class', 'marker-cluster-pie-label')
    .attr('text-anchor', 'middle')
    .attr('dy', dy)
    .text(total)
  return svg

# designed for usage as leaflet 'iconCreateFunction'
pieCreateFunction = (cluster) ->
  children = cluster.getAllChildMarkers()
  data = formatPieData(children)
  html = serializeXmlNode(makeSvg(data, children.length))
  return new L.DivIcon
    html: html


module.exports = 
  pieCreateFunction: pieCreateFunction
