map
===

**Master**: &nbsp; [![Build Status](https://circleci.com/gh/realtymaps/map/tree/master.png?circle-token=1d2b000d3820a249ad236f05210a63f3ebc5cd23)](https://circleci.com/gh/realtymaps/map)&nbsp;

**Develop**:&nbsp;[![Build Status](https://circleci.com/gh/realtymaps/map/tree/develop.png?circle-token=1d2b000d3820a249ad236f05210a63f3ebc5cd23)](https://circleci.com/gh/realtymaps/map)&nbsp;
___

Internal fork from [mean.coffee](https://github.com/realtymaps/mean.coffee)

### How to map

- Install prerequisites
    - foreman run npm install -g coffee-script coffeegulp cgulp bower gulp webpack

- Install dependencies:
    - foreman run npm install (will bower install as well)

- Run the server
    - foreman start

- Run gulp
    - foreman run npm run gulp (for dev)

### Db change management
- handled via Flyway
- [full documentation here](https://realtymaps.atlassian.net/wiki/display/NDS/Database+change+management)

___
### Differences compared to mean.io:

- everything is written with coffeescript
- use gulp instead of grunt
- don't use any template engine:
    - the node.js server only serve static html files
    - angularJS will do the rest (routing + calling the REST API)
- code to manipulate model objects is in the service folder (instead of app/controller in mean.io)
- extra stuff:
    - winston (logger) - lib/logger.coffee
    - memwatch (for memory leaks) - server.coffee
    - nodetime (monitoring) - server.coffee
    - browserSync (live reload browser)
      - gulp/tasks/express.coffee - via nodemon
      - gulp/tasks/browserSync.coffee
        - syncs with express server to reload client pages on server changes

    - webpack - CommonJS for the Browser! Main Files
      - gulp/tasks/webpack.conf
        - tells webpack what client side code to pack via gulp globs
      - webpack.conf.coffee
        - tells webpack where to resolve client side modules. **node_modules**
        was excluded on purpose! **bower_components** is being used instead
    - nginx - (works on OSX only)
      - self contained nginx installer for local development as a front for static assets
      - this is planned a start around nginx-buildpack for Heroku
      - actual build pack to use is here https://github.com/ryandotsmith/nginx-buildpack

___
### TODO

- forever script + git hook for custom deployment
- procfile for heroku deployment
- nginx-buildpack for Heroku see above
- make nginx installer work on more than OSX
- mocha/karma frontend tests with or without web-pack
- npm run gulp-prod (for prod)
- remove mongo or add Postgres
