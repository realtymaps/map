# this constructor expects to be passed a list of string names, and will create an object representing the enum,
# with each value from the list given an object with an "id" corresponding to the index of the value and a "name"
# corresponding to the value itself.  In addition to the getByName(), getById(), and getEnum() methods defined
# below, this enum also provides aliases for use in the code.  It will create a default alias for each value by
# uppercasing the value, and optionally a map of additional aliases can be passed in as well.  For example:
#
# var Status = new Enum(['active', 'inactive', 'deleted'], {ENABLED: 'active'});
# expect(Status.ENABLED).toBe(Status.ACTIVE);
# expect(Status.DELETED.name).toBe('deleted');
# expect(Status.ENABLED.name).toBe('active');
# expect(Status.INACTIVE.id).toBe(1);
# expect(Status.getByName('inactive')).toBe(STATUS.INACTIVE);
# expect(Status.getById(1)).toBe(STATUS.INACTIVE);
# expect(Status.getEnum()[2]).toEqual(Status.getById(2));
#
# NOTE: for efficiency, none of the return values are copied before being passed back.  This means they could be
# altered by external code.  Don't do it.

class Enum
  constructor: (names, aliases) ->
    enumList = []
    nameHash = {}
  
    # main setup
    i = 0
  
    while i < list.length
      if typeof (list[i]) is "string"
        tmpEnumItem =
          id: i
          name: list[i]
      else
        tmpEnumItem = list[i]
        tmpEnumItem.id = i if not tmpEnumItem.id and tmpEnumItem.id isnt 0
  
      # for the main list and id-lookup
      enumList[tmpEnumItem.id] = tmpEnumItem
  
      # for name lookup
      nameHash[tmpEnumItem.name] = tmpEnumItem
  
      # as an enum alias
      this[tmpEnumItem.name.replace(/\W/g, "_").toUpperCase()] = tmpEnumItem
      i++
  
    # additional alias setup
    aliases = aliases or {}
    for own alias, enumItem of aliases
      this[alias] = nameHash[enumItem]


  # public functions
  getByName: (name) ->
    nameHash[name]

  getById: (id) ->
    enumList[id]

  getEnum: ->
    enumList
