app = require '../app.coffee'

app.constant 'ParcelEnums'.ourNs(),
  status:
    notForSale: 'not for sale'
    sold: 'recently sold'
    pending: 'pending'
    forSale: 'for sale'
    saved: 'saved'
