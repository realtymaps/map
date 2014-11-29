app = require '../app.coffee'

app.constant 'ParcelEnums'.ourNs(),
  forSale:
    Not: 'Not'
    NotRecent: 'Not Recent'
    NotPending: 'Not Pending'
    Active: 'Active'
