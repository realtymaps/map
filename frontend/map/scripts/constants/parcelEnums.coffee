app = require '../app.coffee'

app.constant 'rmapsParcelEnums',
  status:
    notForSale: 'not for sale'
    sold: 'recently sold'
    pending: 'pending'
    forSale: 'for sale'
