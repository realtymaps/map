minSlice = 5
valueFunc = (d) ->
  d.values.length
pathClassFunc = (d) ->
  "category-"+d.data.key.replace(/\ /g,'-')
pathTitleFunc = (d) ->
  return

module.exports = 
  radius: 30
  innerRadius: 10
  strokewidth: 1
  width: 60
  height: 60
  valueFunc: valueFunc
  pathClassFunc: pathClassFunc
  pathTitleFunc: pathTitleFunc