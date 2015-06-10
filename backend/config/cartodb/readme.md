Anonymous Map template: (see cartodb [MAP API](http://docs.cartodb.com/cartodb-platform/maps-api.html))

Example below all deals with the parcels template.

* CREATE
```
curl -X POST 'https://realtymaps.cartodb.com/api/v1/map/named?api_key=c95946d99453dfe16168c2d482f949a3d813f583' -H 'Content-Type: application/json' -d @backend/config/cartodb/parcels.json
```

* GET
```
curl -X POST 'https://realtymaps.cartodb.com/api/v1/map/named/parcels?api_key=c95946d99453dfe16168c2d482f949a3d813f583' -H 'Content-Type: application/json'
```

* UPDATE
```
curl -X PUT 'https://realtymaps.cartodb.com/api/v1/map/named/parcels?api_key=c95946d99453dfe16168c2d482f949a3d813f583' -H 'Content-Type: application/json' -d @backend/config/cartodb/parcels.json
```

* DELETE
```
 'https://realtymaps.cartodb.com/api/v1/map/named/parcels?api_key=c95946d99453dfe16168c2d482f949a3d813f583' -H 'Content-Type: application/json'
```
