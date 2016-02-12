resets = []

mock = (module, key, value) ->
  originalValue = module[key]
  module[key] = value
  reset = () -> module[key] = originalValue
  reset.__mocked__ = true
  resets.push(reset)
  reset

resetAll = () ->
  # reset in backwards order in case something got double-mocked
  while resets.length > 0
    resets.pop()()

module.exports = {mock, resetAll}
