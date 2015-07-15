module.exports =
  backend:
    method: 'all'
    order: 9998 # needs to be first
  admin:
    method: 'all'
    order: 9999 # needs to be next to last
  frontend:
    method: 'all'
    order: 10000 # needs to be last
