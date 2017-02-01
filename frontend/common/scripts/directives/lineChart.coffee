mod = require '../module.coffee'
d3 = require 'd3'
require 'd3-time'


mod.directive 'rmapsLineChart', ($log, $parse) ->
  $log = $log.spawn('rmapsLineChartDirective')
  restrict: 'A'
  link: (scope, element, attrs, ctrl) ->
    $log = $log.spawn('rmapsStatsSignups')
    element[0].className += ' line-chart'

    optionsStr = attrs.rmapsLineChart
    $log.debug -> "optionsStr: #{optionsStr}"

    options = $parse(optionsStr)(scope)

    dayField = options.fields?.day || 'date'
    valueField = options.fields?.value || 'value'

    if !scope.chart?
      $log.warn('no chart data to bind to.')

    m = [79, 80, 160, 79]
    w = (options.width || 1280) - m[1] - m[3]
    h = (options.height || 800) - m[0] - m[2]

    parse = d3.time.format(options.format || "%Y-%m-%d").parse
    # format = d3.time.format("%Y")

    # Scales. Note the inverted domain for the y-scale: bigger is up!
    x = d3.time.scale().range([0, w])
    y = d3.scale.linear().range([h, 0])
    xAxis = d3.svg.axis().scale(x).orient("bottom").tickSize(-h, 0).tickPadding(6)
    yAxis = d3.svg.axis().scale(y).orient("right").tickSize(-w).tickPadding(6)

    draw = () ->
      svg.select("g.x.axis").call(xAxis)
      svg.select("g.y.axis").call(yAxis)
      svg.select("path.area").attr("d", area)
      svg.select("path.line").attr("d", line)
      # d3.select("#footer span").text("U.S. Commercial Flights, " + x.domain().map(format).join("-"))


    zoom = () ->
      d3.event.target.x(x)
      draw()

    # An area generator.
    area = d3.svg.area()
      .interpolate("step-after")
      .x((d) -> x(d.date))
      .y0(y(0))
      .y1((d)  -> y(d.value))

    # A line generator.
    line = d3.svg.line()
      .interpolate("step-after")
      .x((d) -> x(d.date))
      .y((d) -> y(d.value))

    svg = d3.select(element[0])
      .append("svg:svg")
      .attr("width", w + m[1] + m[3])
      .attr("height", h + m[0] + m[2])
      .append("svg:g")
      .attr("transform", "translate(" + m[3] + "," + m[0] + ")")

    gradient = svg.append("svg:defs")
      .append("svg:linearGradient")
      .attr("id", "gradient")
      .attr("x2", "0%")
      .attr("y2", "100%")

    gradient.append("svg:stop")
      .attr("offset", "0%")
      .attr("stop-color", "#fff")
      .attr("stop-opacity", .5)

    gradient.append("svg:stop")
      .attr("offset", "100%")
      .attr("stop-color", "#999")
      .attr("stop-opacity", 1)

    svg.append("svg:clipPath")
      .attr("id", "clip")
      .append("svg:rect")
      .attr("x", x(0))
      .attr("y", y(1))
      .attr("width", x(1) - x(0))
      .attr("height", y(0) - y(1))

    svg.append("svg:g")
      .attr("class", "y axis")
      .attr("transform", "translate(" + w + ",0)")

    svg.append("svg:path")
      .attr("class", "area")
      .attr("clip-path", "url(#clip)")
      .style("fill", "url(#gradient)")

    svg.append("svg:g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + h + ")")

    svg.append("svg:path")
      .attr("class", "line")
      .attr("clip-path", "url(#clip)")

    pane = svg.append("svg:rect")
      .attr("class", "pane")
      .attr("width", w)
      .attr("height", h)

    if options.doZoom
      pane.call(d3.behavior.zoom().on("zoom", zoom))

    scope.$on '$destroy', ->
      svg.remove()

    scope.$watchCollection (() -> options),  ->
      if !options.data?.length
        return

      {data} = options


      # Parse dates and numbers.
      data.forEach (d) ->

        d.date = parse( d[dayField])
        d.value = +d[valueField]

      # Compute the maximum price.
      x.domain(scope.chart.domain)
      y.domain([0, d3.max(data, (d) -> return d.value)])

      # Bind the data to our path elements.
      svg.select("path.area").data([data])
      svg.select("path.line").data([data])

      draw()
