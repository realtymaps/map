require '../../../globals'
{Crud, HasManyCrud, hasManyCrud} = require '../../../../backend/utils/crud/util.crud.service.helpers'
tables = require '../../../../backend/config/tables'
userServices = require '../../../../backend/services/services.user'

tables.auth.permission() # calling this to bootstrap the tables queries; see tables.coffee

HasManyCrudInstance = hasManyCrud(tables.auth.permission, [
  "#{tables.auth.m2m_user_permission.tableName}.id as id"
  "user_id"
  "permission_id"
  "content_type_id"
  "name"
  "codename"
], userServices.m2m_user_permission, "permission_id", undefined, "#{tables.auth.m2m_user_permission.tableName}.id")

describe 'util.crud.service.helpers', ->
  describe 'Crud', ->
    it 'exists', ->
      Crud.should.be.ok

    describe 'defaults', ->
      before ->
        @instance = new Crud(tables.auth.user)
      it 'ctor', ->
        @instance.dbFn.should.be.equal tables.auth.user
        @instance.idKey.should.be.equal 'id'
      it 'getAll', ->
        @instance.getAll().toString().should.equal 'select * from "auth_user"'

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "#{tables.auth.user.tableName}" where "id" = '1'"""

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "#{tables.auth.user.tableName}" set "test" = 'test' where "id" = '1'"""

        it 'safe', ->
          @instance.update(1, {test:'test', crap: 2}, ['test']).toString()
          .should.equal """update "#{tables.auth.user.tableName}" set "test" = 'test' where "id" = '1'"""

      describe 'create', ->
        it 'default', ->
          @instance.create(1, {test:'test'}).toString()
          .should.equal """insert into "#{tables.auth.user.tableName}" ("id", "test") values ('1', 'test')"""
        it 'id', ->
          @instance.create(2, {id: 1, test:'test'}).toString()
          .should.equal """insert into "#{tables.auth.user.tableName}" ("id", "test") values ('2', 'test')"""

      it 'delete', ->
        @instance.delete(1).toString()
        .should.equal """delete from "#{tables.auth.user.tableName}" where "id" = '1'"""

    describe 'overrides', ->
      before ->
        @instance = new Crud(tables.auth.user, 'project_id')

      it 'ctor', ->
        @instance.dbFn.should.be.equal tables.auth.user
        @instance.idKey.should.be.equal 'project_id'

      it 'getAll', ->
        @instance.getAll().toString().should.equal "select * from \"#{tables.auth.user.tableName}\""

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "#{tables.auth.user.tableName}" where "id" = '1'""".replace('id', @instance.idKey)

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "#{tables.auth.user.tableName}" set "test" = 'test' where "id" = '1'""".replace('id', @instance.idKey)

        it 'safe', ->
          @instance.update(1, {test:'test', crap: 2}, ['test']).toString()
          .should.equal """update "#{tables.auth.user.tableName}" set "test" = 'test' where "id" = '1'""".replace('id', @instance.idKey)

      describe 'create', ->
        it 'default', ->
          @instance.create(undefined, {project_id:1, test:'test'}).toString()
          .should.equal """insert into "#{tables.auth.user.tableName}" ("id", "test") values ('1', 'test')""".replace('id', @instance.idKey)
        it 'id', ->
          @instance.create(2, {test:'test'}).toString()
          .should.equal """insert into "#{tables.auth.user.tableName}" ("id", "test") values ('2', 'test')""".replace('id', @instance.idKey)

      it 'delete', ->
        @instance.delete(1).toString()
        .should.equal """delete from "#{tables.auth.user.tableName}" where "id" = '1'""".replace('id', @instance.idKey)


    describe 'HasManyCrud', ->
      it 'exists', ->
        HasManyCrud.should.be.ok

      describe 'defaults', ->
        before ->
          @instance = HasManyCrudInstance

        it 'ctor', ->
          @instance.dbFn.should.be.equal tables.auth.permission
          @instance.idKey.should.be.equal "#{tables.auth.m2m_user_permission.tableName}.id"
          @instance.joinCrud.should.be.equal userServices.m2m_user_permission

        it 'getAll', ->
          @instance.getAll(user_id:1).toString().should.equal """
          select "#{tables.auth.m2m_user_permission.tableName}"."id" as "id", "user_id", "permission_id",
           "content_type_id", "name", "codename" from "#{tables.auth.m2m_user_permission.tableName}"
           inner join "#{tables.auth.permission.tableName}" on "#{tables.auth.permission.tableName}"."id" = "permission_id"
           where "user_id" = '1'""".replace(/\n/g, '')

        it 'getById', ->
          @instance.getById(1).toString()
          .should.equal """
          select "#{tables.auth.m2m_user_permission.tableName}"."id" as "id", "user_id", "permission_id",
           "content_type_id", "name", "codename" from "#{tables.auth.m2m_user_permission.tableName}"
           inner join "#{tables.auth.permission.tableName}" on "#{tables.auth.permission.tableName}"."id" = "permission_id"
           where "#{tables.auth.m2m_user_permission.tableName}"."id" = '1'""".replace(/\n/g, '')

        describe 'update', ->
          it 'no safe', ->
            @instance.update(1, test:'test').toString()
            .should.equal """update "#{tables.auth.m2m_user_permission.tableName}" set "test" = 'test' where "id" = '1'"""

          it 'safe', ->
            @instance.update(1, {test:'test', crap:2}, ['test']).toString()
            .should.equal """update "#{tables.auth.m2m_user_permission.tableName}" set "test" = 'test' where "id" = '1'"""


        describe 'create', ->
          it 'default', ->
            @instance.create(1, {test:'test'}).toString()
            .should.equal """insert into "#{tables.auth.m2m_user_permission.tableName}" ("id", "test") values ('1', 'test')"""
          it 'id', ->
            @instance.create(2, {id: 1, test:'test'}).toString()
            .should.equal """insert into "#{tables.auth.m2m_user_permission.tableName}" ("id", "test") values ('2', 'test')"""

        it 'delete', ->
          @instance.delete(1).toString()
          .should.equal """delete from "#{tables.auth.m2m_user_permission.tableName}" where "id" = '1'"""
