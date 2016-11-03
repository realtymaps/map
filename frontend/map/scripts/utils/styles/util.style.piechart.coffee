radius = 27
innerRadius = 16
strokewidth = 1
arcOffset = 1 #shimmy the arcs & text away from pie-frame border to ensure no clipping
width = (4*strokewidth)+(2*radius)
height = width
textyOffset = '.4em' #amount of drop for number value in center

# return count of given parcel type
valueFunc = (c) ->
  # exposing c (total parcel count) here in case normalizing becomes necessary later
  (d) ->
    d.values.length

# return class denoting parcel type (see piechart.styl)
pathClassFunc = (d) ->
  'category-'+d.data.key.replace(/\ /g,'-')

# provide a title for the parcel type when hovering over the arc
pathTitleFunc = (d) ->
  d.data.key.replace(/\ /g,'-')

module.exports ={
  radius
  innerRadius
  strokewidth
  arcOffset
  width
  height
  textyOffset
  valueFunc
  pathClassFunc
  pathTitleFunc
}
