d3 = require 'd3'

serializeXmlNode = (xmlNode) ->
  if (typeof window.XMLSerializer != "undefined")
    return (new window.XMLSerializer()).serializeToString(xmlNode)
  if (typeof xmlNode.xml != "undefined")
    return xmlNode.xml
  return "";

module.exports =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: "markercluster"
    visible: true
    layerOptions:
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true
      iconCreateFunction: (cluster) ->
        children = cluster.getAllChildMarkers()
        c = children.length

        data = d3.nest()
        .key (k) ->
          k.options.rm_status
        .sortKeys(d3.descending)
        .entries children, d3.map


        strokewidth = 1
        r = 30
        rinner = 10
        label = c
        w = (r+1)*2
        h = w
        valueFunc = (d) ->
          # return if (d.values.length/c > 0.02) then d.values.length else (d.values.length + ((d.values.length-(0.02*c))/0.02))
          d.values.length
        pathClassFunc = (d) ->
          "category-"+d.data.key.replace(/\ /g, '-')
        donut = d3.layout.pie()
        arc = d3.svg.arc().outerRadius(r).innerRadius(rinner)
        svg = document.createElementNS(d3.ns.prefix.svg, 'svg')
        vis = d3.select(svg)
          .data([data])
          .attr('class', 'pieClass')
          .attr('width', w)
          .attr('height', h)

        arcs = vis.selectAll('g.arc')
          .data(donut.value(valueFunc))
          .enter().append('svg:g')
          .attr('class', 'arc')
          .attr('transform', 'translate('+r+','+r+')')

        arcs.append('svg:path')
          .attr('class', pathClassFunc)
          .attr('stroke-width', strokewidth)
          .attr('d', arc)
          .append('svg:title')
          .text('pathTitleFunc')

        vis.append('text')
          .attr('x', r)
          .attr('y', r)
          .attr('class', 'marker-cluster-pie-label')
          .attr('text-anchor', 'middle')
          .attr('dy', '.5em')
          .text(c)

        html = serializeXmlNode(svg)
        return new L.DivIcon({ html: html });

  backendPriceCluster:
    name: 'Price Cluster'
    type: 'group'
    visible: true

  addresses:
    name: 'Addresses'
    type: 'group'
    visible: true
