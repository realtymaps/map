dbs = require '../config/dbs'
{userData} = '../config/tables'
# DEPRECATED: we will stop using this (and bookshelf.js) in favor of /config/tables.coffee and knex

module.exports = dbs.users.Model.extend
  tableName: 'project'#userData.project.tableName
