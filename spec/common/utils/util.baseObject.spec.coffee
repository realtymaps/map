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
      # console.log _.functions animal
      animal.base(animal, 'speak').should.equal "nope"
    it 'Wolf', ->
      wolf.base('speak').should.equal "howl"
    it 'Dog', ->
      dog.base('speak').should.equal "howl"
    it 'Cat', ->
      cat.base('speak').should.equal "nope"
