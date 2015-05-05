minSlice = 5
radius = 27
innerRadius = 16
strokewidth = 1


valueFunc = (d) ->
  # return if (d.values.length/c > 0.02) then d.values.length else (d.values.length + ((d.values.length-(0.02*c))/0.02))
  d.values.length

pathClassFunc = (d) ->
  "category-"+d.data.key.replace(/\ /g,'-')

pathTitleFunc = (d) ->
  d.data.key.replace(/\ /g,'-')

module.exports = 
  radius: radius
  innerRadius: innerRadius
  strokewidth: strokewidth
  width: 60
  height: 60
  valueFunc: valueFunc
  pathClassFunc: pathClassFunc
  pathTitleFunc: pathTitleFunc