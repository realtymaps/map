arrayify = (obj) ->
  return [] if !obj?
  if Array.isArray obj then obj else [obj]

module.exports = {
  arrayify
}
