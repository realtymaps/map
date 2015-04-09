scripts
=======

## Using these scripts

It is entirely likely situations will arise that aren't covered by the current setup.  Rather than over-engineering
now for what might happen later, a best effort has been made for now and improvements or changes will need to be made
later.

#### Script folders
* app: these are scripts that perform common app functions, such as clean, serve, etc
* database: these are scripts that perform common tasks related to our databases.
* environmentNormalization: these are scripts that normalize use of commands across our local boxes, circleCI
instances, and Heroku dynos.
* misc: other things that don't have a good place

#### DB Specifiers
Various scripts may refer to or use a "db specifier".  A db specifier can be one of the following (if a given db
specifier could be interpreted multiple ways, it is interpreted in the first of the following which results in a valid
conninfo URL):
  * a conninfo URL, of the format defined in http://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39156
  * an environment variable fragment, where the environment variable <FRAGMENT>_VARIABLE resolves to the name of an
  environment variable which resolves to a conninfo URL
  * an environment variable fragment, where the environment variable <FRAGMENT>_URL resolves to a conninfo URL
  * an environment variable fragment appended with `@` then the name of an heroku app, which is treated like an
  environment variable fragment as described above, except where all resolutions take place in the context of the
  given heroku app's environment
    * example: `USER_DATABASE@realtymaps-map`

## database scripts

#### High-level intent of commonly-used scripts
* `clonePropertyData` and `cloneUserData` can be used with `-t` options (possibly preceded by `--clean`) to manually
copy specific tables from prod or staging to dev.  With `--to`, it will copy tables to prod or staging instead of from,
in case you want to do some tweaking locally and then clone the results up.
* `syncPropertyData`, `syncUserData`, and `syncAll` can be used to run migrations.  `--breaking` should be used only
when it is OK for breaking changes to be made (e.g. during app startup).
* `init` can be used to initially clone the dbs from production, or (with lots of caution!) to clone the dbs from local
to staging (or accidentally production!).

#### Low-level scripts
* `./scripts/database/clone` is a generic script that clones tables (schema+data) from one db to another.  Arguments
are:
  * the source db specifier
  * the destination db specifier
  * <optional> `--oids` to clone OIDs as well; this makes the whole process less efficient, but is necessary if there
  are foreign key constraints that will need to be maintained through the clone.
  * <optional> `--clean` to drop existing objects in the db before restoring them.  Note that this will not work if the
  objects are not present, as it will cause an error and roll back the restore.
  * <optional> any dump/restore options (such as `-t table1 -t table2` to clone just table1 and table2).  These will be
  passed directly on to pg_dump.  Default behavior if no options are passed here is to clone all objects in the db (not
  just tables).
* `foreman run ./scripts/database/getDbUrl` makes it much simpler (and more explicit) to use db urls with the other
scripts.  It takes a db specifier as an argument and echos the resolved conninfo URL.
* `foreman run ./scripts/database/getDbName` takes a db specifier, and returns the db name if the specifier was a
conninfo URL, or the specifier itself if it wasn't a conninfo URL
  
#### Direct-use scripts
* `foreman run ./scripts/database/clonePropertyData` clones tables from one db to the currently-configured property db,
then (by default) marks all materialized views as dirty.  Arguments are:
  * <optional> `--to` reverses the direction of the clone
  * a db specifier to use as the source (or the destination, if preceded by `--to`).
  * <optional> `--clean` to force removal of objects before recreating them -- note this will cause errors if the
  objects don't already exist
  * <optional> `--no-rebuild` prevents the normal action of marking all materialized views on the destination db as
  dirty
  * <optional> any dump/restore options (such as `-t table1 -t table2` to clone just table1 and table2).  Default is to
  dump the following tables: corelogic_deed, corelogic_tax, mls_listings, parcels (the source data tables).
* `foreman run ./scripts/database/cloneUserData` clones tables from one db to the currently-configured user db.
Arguments are:
  * <optional> `--to` reverses the direction of the clone
  * a db specifier to use as the source (or the destination, if preceded by `--to`).
  * <optional> `--clean` to force removal of objects before recreating them -- note this will cause errors if the
  objects don't already exist
  * <optional> any dump/restore options (such as `-t table1 -t table2` to clone just table1 and table2).  Default is to
  dump all the tables in the public schema.
* `foreman run ./scripts/database/syncPropertyData` performs the following actions:
  * updates the property db with the latest migrations from `./scripts/sql/propertyData` (recursively)
  * stages any materialized views that have been marked dirty -- this will typically be the slowest part of the script
  * pushes any non-breaking materialized views that have been staged, unless `--breaking` is an argument, in which case
  all staged views are pushed
* `foreman run ./scripts/database/syncUserData` updates the user db with the latest migrations from
`./scripts/sql/userManagement` (recursively)
* `foreman run ./scripts/database/test` runs test migrations from `./scripts/sql/test/`.
  * Adding `--fresh` will cause the test db to be dropped and recreated first.
  * Any additional arguments passed to `test` will be passed directly to `dbsync` to aid in testing.
  * There are 2 test migrations set up; the first will create a table in the test db, and the second will run a
  migration which will fail and roll back without changes.

#### Convenience scripts
* `foreman run ./scripts/database/syncAll` runs `syncPropertyData` then `syncUserData`.  If `--breaking` is given as an
argument, it will be passed on to `syncPropertyData`. 
* `foreman run ./scripts/database/init` is intended for use with a set of clean-slate dbs (with extensions installed
appropriately), and will result in a fully-synced set of dbs.  By default, the destination dbs are the
currently-configured ones.
  * Arguments are:
    * <optional> `--to` reverses the direction of the initialization
    * source property db (or destination if preceded by `--to`)
    * source user db (or destination if preceded by `--to`)
    * <optional> `--clean` will be passed on to both clone scripts
  * `init` will then execute the following scripts (in this order):
    * `dbsync` migrations from the `./scripts/sql/propertyData/-bootstrap` directory to the destination propertyData db
    * `clonePropertyData`
    * `syncPropertyData --breaking`
    * `cloneUserData`
    * `syncUserData`

## environmentNormalization scripts
* `source ./scripts/environmentNormalization/dbsync` ensures dbsync is available for use by other scripts.  It finds
dbsync installed either locally in the current working directory, or on the PATH.  If it can't find it, it uses npm to
install dbsync at the current working directory.  It then exports a DBSYNC environment variable with the location of
dbsync.
* `./scripts/environmentNormalization/herokuCli` executes a heroku toolbelt command using `hk`, installing it first if
needed. The syntax is `./scripts/environmentNormalization/herokuCli <herokuAppName> <herokuCommand> [other params]`.

## misc scripts
* `./scripts/misc/cleanBower [moduleName]` clears the bower cache, removes dependencies, and then runs `bower install`.
If a moduleName is included, it only clears and removes that module.
* `./scripts/misc/devPreInstall` installs convenient global npm packages
* `./scripts/misc/pruneOldGitBranches [comparisonBranchName]` deletes all branches, local and remote, that are fully
merged to the comparison branch and have not been modified within the last 2 weeks.  It contains a hard-coded list of
exception branches which will never be deleted, currently set to master and HEAD, and a hard-coded list of exception
remotes on which no branches will be deleted, currently set to prod and upstream.
* `./scripts/misc/pushTo <service> <projectName> [--dbsyc]` is intended to be run from within CircleCI only.  The
service can be either 'heroku' or 'github', and the project is the destination github project or heroku app.  It
performs misc tasks related to such pushes.  If `--dbsync` is present, it will also run non-breaking dbsync migrations
before attempting the push/deploy.
* `./scripts/misc/setHerokuStack <stack>` will set the heroku stack for all apps accessible by the credentialled user.
* `source ./scripts/misc/syncVars` sets PROPERTY_DATABASE_URL and USER_DATABASE_URL based on the values of other
environment variables.
