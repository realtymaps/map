require '../../../globals'
{Crud, HasManyCrud, hasManyCrud} = require '../../../../backend/utils/crud/util.crud.service.helpers'
{userData} = require '../../../../backend/config/tables'
userServices = require '../../../../backend/services/services.user'


HasManyCrudInstance = hasManyCrud(userData.auth_permission, [
  "#{userData.auth_user_user_permissions.tableName}.id as id"
  "user_id"
  "permission_id"
  "content_type_id"
  "name"
  "codename"
], userServices.auth_user_user_permissions, "permission_id", undefined, "auth_user_user_permissions.id")

describe 'util.crud.service.helpers', ->
  describe 'Crud', ->
    it 'exists', ->
      Crud.should.be.ok

    describe 'defaults', ->
      before ->
        @instance = new Crud(userData.user)
      it 'ctor', ->
        @instance.dbFn.should.be.equal userData.user
        @instance.idKey.should.be.equal 'id'
      it 'getAll', ->
        @instance.getAll().toString().should.equal 'select * from "auth_user"'

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "auth_user" where "id" = '1'"""

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "auth_user" set "test" = 'test' where "id" = '1'"""

        it 'safe', ->
          @instance.update(1, {test:'test', crap: 2}, ['test']).toString()
          .should.equal """update "auth_user" set "test" = 'test' where "id" = '1'"""

      describe 'create', ->
        it 'default', ->
          @instance.create({id:1, test:'test'}).toString()
          .should.equal """insert into "auth_user" ("id", "test") values ('1', 'test')"""
        it 'id', ->
          @instance.create({id:1, test:'test'}, 2).toString()
          .should.equal """insert into "auth_user" ("id", "test") values ('2', 'test')"""

      it 'delete', ->
        @instance.delete(1).toString()
        .should.equal """delete from "auth_user" where "id" = '1'"""

    describe 'overrides', ->
      before ->
        @instance = new Crud(userData.user, 'project_id')

      it 'ctor', ->
        @instance.dbFn.should.be.equal userData.user
        @instance.idKey.should.be.equal 'project_id'

      it 'getAll', ->
        @instance.getAll().toString().should.equal 'select * from "auth_user"'

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "auth_user" where "id" = '1'""".replace('id', @instance.idKey)

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "auth_user" set "test" = 'test' where "id" = '1'""".replace('id', @instance.idKey)

        it 'safe', ->
          @instance.update(1, {test:'test', crap: 2}, ['test']).toString()
          .should.equal """update "auth_user" set "test" = 'test' where "id" = '1'""".replace('id', @instance.idKey)

      describe 'create', ->
        it 'default', ->
          @instance.create({project_id:1, test:'test'}).toString()
          .should.equal """insert into "auth_user" ("id", "test") values ('1', 'test')""".replace('id', @instance.idKey)
        it 'id', ->
          @instance.create({test:'test'}, 2).toString()
          .should.equal """insert into "auth_user" ("id", "test") values ('2', 'test')""".replace('id', @instance.idKey)

      it 'delete', ->
        @instance.delete(1).toString()
        .should.equal """delete from "auth_user" where "id" = '1'""".replace('id', @instance.idKey)


    describe 'HasManyCrud', ->
      it 'exists', ->
        HasManyCrud.should.be.ok

      describe 'defaults', ->
        before ->
          @instance = HasManyCrudInstance

        it 'ctor', ->
          @instance.dbFn.should.be.equal userData.auth_permission
          @instance.idKey.should.be.equal "auth_user_user_permissions.id"
          @instance.joinCrud.should.be.equal userServices.auth_user_user_permissions

        it 'getAll', ->
          @instance.getAll(user_id:1).toString().should.equal """
          select "auth_user_user_permissions"."id" as "id", "user_id", "permission_id",
           "content_type_id", "name", "codename" from "auth_user_user_permissions"
           inner join "auth_permission" on "auth_permission"."id" = "permission_id"
           where "user_id" = '1'""".replace(/\n/g, '')

        it 'getById', ->
          @instance.getById(1).toString()
          .should.equal """
          select "auth_user_user_permissions"."id" as "id", "user_id", "permission_id",
           "content_type_id", "name", "codename" from "auth_user_user_permissions"
           inner join "auth_permission" on "auth_permission"."id" = "permission_id"
           where "auth_user_user_permissions"."id" = '1'""".replace(/\n/g, '')

        describe 'update', ->
          it 'no safe', ->
            @instance.update(1, test:'test').toString()
            .should.equal """update "auth_user_user_permissions" set "test" = 'test' where "id" = '1'"""

          it 'safe', ->
            @instance.update(1, {test:'test', crap:2}, ['test']).toString()
            .should.equal """update "auth_user_user_permissions" set "test" = 'test' where "id" = '1'"""


        describe 'create', ->
          it 'default', ->
            @instance.create({id:1, test:'test'}).toString()
            .should.equal """insert into "auth_user_user_permissions" ("id", "test") values ('1', 'test')"""
          it 'id', ->
            @instance.create({id:1, test:'test'}, 2).toString()
            .should.equal """insert into "auth_user_user_permissions" ("id", "test") values ('2', 'test')"""

        it 'delete', ->
          @instance.delete(1).toString()
          .should.equal """delete from "auth_user_user_permissions" where "id" = '1'"""
