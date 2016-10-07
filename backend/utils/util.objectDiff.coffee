
objectDiff = (o1, o2, level='') ->
  if o1 == o2
    return
  if typeof(o1) != 'object' || typeof(o2) != 'object'
    console.log "===#{level} -> "+JSON.stringify(o1)
    console.log "---#{level} -> "+JSON.stringify(o2)
    return
  for k of o1
    if !(k of o2)
      console.log "===#{level}.\"#{k}\" -> "+JSON.stringify(o1[k])
      console.log "---#{level}.\"#{k}\" ->"
    else
      objectDiff(o1[k], o2[k], level+'."'+k+'"')
  for k of o2 when !(k of o1)
    console.log "===#{level}.\"#{k}\" ->"
    console.log "---#{level}.\"#{k}\" -> "+JSON.stringify(o2[k])
  return undefined

module.exports = objectDiff
