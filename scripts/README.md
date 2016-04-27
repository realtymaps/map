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
    * example: `MAIN_DATABASE@realtymaps-map`

## database scripts

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
* `foreman run ./scripts/database/syncDb <label> [app]` performs the following actions:
  * updates the <label> db (on the [app] heroku app, if included) with the latest migrations from
  `./scripts/migrations/<label>` (recursively)

## environmentNormalization scripts
* `source ./scripts/environmentNormalization/dbsync` ensures dbsync is available for use by other scripts.  It finds
dbsync installed either locally in the current working directory, or on the PATH.  If it can't find it, it uses npm to
install dbsync at the current working directory.  It then exports a DBSYNC environment variable with the location of
dbsync.

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
performs misc tasks related to such pushes.  If `--dbsync` is present, it will also run dbsync migrations
before attempting the push/deploy.
* `./scripts/misc/allHerokuApps <command> [args]` will execute a command on all heroku apps accessible by the
credentialled user.  For example, `./scripts/misc/allHerokuApps config:set FOO=bar`
* `./scripts/misc/externalAccount <action> <data> [app list...]` will set API keys and other account info in one or more
app databases.
  * `action` can be either 'get', 'insert', 'update', and 'delete'
  * `data` is a coffeescript-style object string, such as
`'name: "test", api_key: "1234qwert5678"'` or `'{name: "foo", username: "bar", password: "baz", environment: "production"}'`
  * The remaining arguments are the apps on which to set the values.  Each argument can be a staging prefix (such as
  `joe` or `nem`), `prod`/`production`, `local`/`localhost`, or a fully-qualified app name (such as `dan-realtymaps-map`
  or `realtymaps-map`).  If no apps are listed, the values will be set on all heroku apps accessible by the
  credentialled user.
* `./scripts/misc/externalSubscribe <stripe_customer_id> <plan_id> [app list...]` runs `./scripts/misc/subscribe` on
external environments provided by the app list.  This is helpful for remote manual subscription setup.
  * `stripe_customer_id` corresponds to `auth_user.stripe_customer_id` that is created upon account creation.
  * `plan_id` references a plan.  Possible values include 'pro' and 'standard'.
  * The remaining arguments act similar as above in `./scripts/misc/externalAccount`, however the default for an
  empty list is to run on localhost only.
