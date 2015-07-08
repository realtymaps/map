{Crud} = require '../../../../backend/utils/crud/util.crud.service.helpers'
{userData} = require '../../../../backend/config/tables'
{user} = userData

describe 'util.crud.service.helpers', ->
  describe 'Crud', ->
    it 'exists', ->
      Crud.should.be.ok

    describe 'defaults', ->
      before ->
        @instance = new Crud(user)
      it 'ctor', ->
        @instance.dbFn.should.be.equal user
        @instance.idKey.should.be.equal 'id'
      it 'getAll', ->
        @instance.getAll().toString().should.equal 'select * from "auth_user"'

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "auth_user" where "id" = '1'"""

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "auth_user" set  where "id" = '1'"""

        it 'safe', ->
          @instance.update(1, {test:'test'}, ['test']).toString()
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
        @instance = new Crud(user, 'project_id')

      it 'ctor', ->
        @instance.dbFn.should.be.equal user
        @instance.idKey.should.be.equal 'project_id'

      it 'getAll', ->
        @instance.getAll().toString().should.equal 'select * from "auth_user"'

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "auth_user" where "id" = '1'""".replace('id', @instance.idKey)

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "auth_user" set  where "id" = '1'""".replace('id', @instance.idKey)

        it 'safe', ->
          @instance.update(1, {test:'test'}, ['test']).toString()
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
