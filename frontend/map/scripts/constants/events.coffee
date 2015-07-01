# app = require '../app.coffee'
# keysToValues = require '../../../../common/utils/util.keysToValues.coffee'

# app.constant 'rmapsevents',
#   keysToValues
#     map:
#       drawPolys:
#         isEnabled: 1
#         clear: 1
#         query:  1
#     principal:
#       login:
#         success: 1
#     alert:
#       spawn: 1
#       hide: 1
#       dismiss: 1
#       prevent: 1
#     snail:
#       initiateSend: 1

app = require '../app.coffee'
events = require '../../../common/scripts/constants/events.coffee'
console.log '#### map events'
module.exports = app.constant 'rmapsevents', events
