map
===

[![Circle CI](https://circleci.com/gh/realtymaps/map/tree/master.png?style=badge&circle-token=1d2b000d3820a249ad236f05210a63f3ebc5cd23)](https://circleci.com/gh/realtymaps/map/tree/master)

___

Internal fork from [mean.coffee](https://github.com/realtymaps/mean.coffee)

### How to map:

- **Environment**:
    - **Homebrew (brew)**: **ONLY IF OSX**
        - [install instructions](http://brew.sh) or `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
    - **Ruby (rvm / ruby / foreman)**:
        -  [**rvm**](https://rvm.io/):
            - **IMPORTANT** do not use sudo!
            - `gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3`
            - `\curl -sSL https://get.rvm.io | bash -s stable`
        - **ruby**:
            - `rvm install ruby-2.1.3`
            - *Note if there are problems here it is usually with OSX command line tools being out of sync and missing gcc deps (resolved with brew) and osx commandline tools updates*
        - **foreman**:
            - `gem install foreman`
    - **Node (nvm / node / npm)**:
        - **nvm**:
            - `brew install nvm` or if not osx use google / probabaly `apt-get install nvm`
        - **node**: (via nvm)
            - `nvm install 0.12.7`
            - **.nvmrc**: *(for good measure)* tells nvm which node to load by default
                - `echo 0.12.7 >> ~/.nvmrc`
        - **npm**: This is an optional update to make npm newer than the defaulted npm released with 0.12.7
            - `npm install -g npm` bottom line any npm > 2.12.0 should be good

        - **node global deps** (convenience):
            - `./scripts/misc/devPreInstall`   (installs things like coffeescript, gulp, karma and junk so the shell can pick it up easily without `npm run whatever`)
            -  **JWI: it shouldn't actually be necessary to install anything globally to
            run our app...  ideally "npm install" should handle everything, which also
            makes Heroku setup simpler**

    - **Application** (make sure you are at the root path of the source code base for map! Where bower.json and package.json are present)
        - `npm install` (will bower install as well)
        - You made bower changes and feel like updating that only.. well then run `bower install`

        - **Run gulp (for dev)**

            - Requires Postgress Database Locally:
                - `foreman run gulp` or
                - `foreman run scripts/runDev`

            - Remote Heroku Database:
                - `foreman run scripts/runDev --bare-server`

        - **Run the server (HEROKU ONLY)**
            - `foreman start`

### Db change management
- [full documentation here](https://realtymaps.atlassian.net/wiki/display/NDS/Database+change+management)


___
### LOCK DOWN
`npm install -g npm-shrinkwrap`
execute
`npm-shrinkwrap`

### TODO

- forever script + git hook for custom deployment
- nginx-buildpack for Heroku see above
- make nginx installer work on more than OSX
- mocha/karma frontend tests with or without web-pack
- npm run gulp-prod (for prod)
- figure out if global prequisite install is actually necessary
- set things up so "foreman start" will do what we want for every environment
- fork memoizee and add option for understanding promises (so it can, at least optionally, choose not to cache rejected promises
- fix coffescript source-mappings for stacktraces / log output
- fix warn logging
