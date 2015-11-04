BaseObject = require '../../../common/utils/util.baseObject.coffee'
_ = require 'lodash'

class Animal extends BaseObject
  speak: ->
    "nope"
  base: ->
    if arguments.length == 1
      return super([Animal, @].concat(_.toArray(arguments))...)
    super([Animal].concat(_.toArray(arguments))...)

class Wolf extends Animal
  speak: ->
    "howl"

  base: ->
    BaseObject::base([Wolf,@].concat(_.toArray(arguments))...)

class Dog extends Wolf
  speak: ->
    "bark"

class Cat extends Animal
  speak: ->
    "Meow"

animal = new Animal()
wolf = new Wolf()
dog = new Dog()
cat = new Cat()

describe 'util.baseObject', ->
  describe 'base', ->
    it 'Animal', ->
      animal.base(animal, 'speak').should.equal "nope"
    it 'Wolf', ->
      wolf.base('speak').should.equal "howl"
    it 'Dog', ->
      dog.base('speak').should.equal "howl"
    it 'Cat', ->
      cat.base('speak').should.equal "nope"

  describe 'extend and include', ->
    beforeEach ->
      PersonModule =
        changePersonName: (person, name)->
          person.name = name
          person
        killPersonsName: (person)->
          delete person.name
          person
      PersonAttributes =
        p_name: 'no_name'
        state: 'no_state'
      @PersonAttributes = PersonAttributes
      class Person extends BaseObject
        @include PersonModule
        @extend PersonAttributes
        constructor: (name, state)->
          @name = if name? then name else Person.p_name
          @state = if state? then state else Person.state
      @name = 'nick'
      @state = 'fl'
      @defaultUsage = new Person()
      @usage = new Person(@name, @state)

    describe 'include specs', ->
      it 'defaults attributes exist', ->
        @defaultUsage.name.should.be.ok
      it 'defaults attributes are correct', ->
        expect(@defaultUsage.name).to.equal(@PersonAttributes.p_name)
        expect(@defaultUsage.state).to.equal(@PersonAttributes.state)
      it 'subject attributes are correct ', ->
        expect(@usage.name).to.equal(@name)
        expect(@usage.state).to.equal(@state)
    describe 'extend specs', ->
      it 'defaults functions exist', ->
        expect(@defaultUsage.changePersonName?).to.be.ok
        expect(@defaultUsage.killPersonsName?).to.be.ok
      it 'subject functions act correctly', ->
        p =  @defaultUsage.changePersonName(_.cloneDeep(@defaultUsage), 'john')
        p2 = @defaultUsage.killPersonsName(@defaultUsage)
        expect(p.name).to.equal('john')
        expect(p2.name).to.equal(undefined)
