module.exports = (app) ->
  app.dbs.users.Model.extend
    tableName: "management_environmentsetting"
