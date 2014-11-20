sprintf = require('sprintf-js').sprintf

AND = " AND "
SELECT =
  """select %s
    from %s
    where
    """.space()

module.exports =
  SELECT: SELECT
  SELECTAll: sprintf(SELECT, '*', '%s')
  AND: AND