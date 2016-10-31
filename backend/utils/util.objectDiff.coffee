
objectDiff = (o1, o2, prefix='', level='') ->
  if o1 == o2
    return
  if typeof(o1) != 'object' || typeof(o2) != 'object'
    console.log "#{prefix}===#{level} -> "+JSON.stringify(o1)
    console.log "#{prefix}---#{level} -> "+JSON.stringify(o2)
    return
  for k of o1
    if !(k of o2)
      console.log "#{prefix}===#{level}.\"#{k}\" -> "+JSON.stringify(o1[k])
      console.log "#{prefix}---#{level}.\"#{k}\" ->"
    else
      objectDiff(o1[k], o2[k], prefix, level+'."'+k+'"')
  for k of o2 when !(k of o1)
    console.log "#{prefix}===#{level}.\"#{k}\" ->"
    console.log "#{prefix}---#{level}.\"#{k}\" -> "+JSON.stringify(o2[k])
  return undefined

module.exports = objectDiff
