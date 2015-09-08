# Dependencies

Please do not copy and paste scripts from websites to be loaded directly via html. Vendor Scripts should be well versioned and come from
bower and or npm.

Therefore please use:

- bower.json (for most frontend)
- package.json (backend and some frontend)

The dependencies are loaded via gulp, main-bower-files, and browserify. When adding a new vendor dependency it really should be nothing more than modifying bower.json and running bower install (automatic via main-bower-files/gulp). 

# File Naming / Renaming

All files that had the naming convention of whatever-list were moved to whatever(s). 

Example: 
notes-list:
 - notes.jade
 - notes.styl
 
Jade Partial naming: We are transitioning to following your lead on having most partials renamed to proceed with a `_` not all have been converted yet.
 
# JS / CS conventions

- use coffeescript
- use require / Common JS where appropriate (like loading `/common/**/*.coffee`)
- `/common/**/*.coffee` is vanilla coffee/js, where `/frontend/common/**/*.coffee` is angular 
- Coffeelint will enforce most issues
- Classes are PascalCase (CamelCaps)
- Collections (Arrays, Lists) are pluralized only specific Array for specific use cases where expliclty needed
- move away from the large controller files to be more granualar (once merged mayday_controllers1 and 2 should dissapear)   

# Route Naming

Please follow conventions of using /common/config/:
- routes.frontend.coffee (provided by angular router usually anything not `/api/*`)
- routes.backend.coffee (express `/api/*`)

#Jade

- `index.jade`: is hosted by express in @ `/backend/map/index.jade` be aware that some of the layout is shared between `/backend/map/admin`
- `/jade/` was mostly moved to `/frontend/map/html/views`
- `/jadePartials/` was mostly moved to `/frontend/map/html/includes`
- `/frontend/map/html/views/templates` is note used much and is mainly for debug stuff loaded by the $templateCache manually

# Stylus:

### Conventions:

- always prefer class (`.`) over id(`#`) selectors some have been transitioned but many have been left alone for merging sake.

- variables: will be proceeded with $ and camelCase example:
 `$white`, *note all `c_whatever` is gone to `$whatever`*
 
- Functions: will be proceeded with $fn and camelCase example:
`$fnSomeFunction()`


### Mapping of Files:

- base.styl - broken up:
    
    - fontend/map/styles/common.styl
    - fontend/map/styles/mobile-nav.styl (`#mobil-nav`)
    - following: was cut (since angular router is being utilized for this) (*can add it back in, but not sure where it should go*) 
            
    ```stylus
      > div
        z-index 0
    
      &.show-map
        #map
          z-index 1
    
      &.show-mail
        #mail
          z-index 1
    
      &.show-history
        #history
          z-index 1
    
      &.show-notes {
        z-index 5
      }
      &.show-favorites {
        z-index 5
      }
    
      @media (max-width: xs-1)
        &.show-content
        &.show-neighbourhoods
          #content
            z-index 4
    ```

# Angular
    
All controllers, factories, services.. etc should  be prepended with rmaps. The main purpose of this is to not conflict with third party angular libraries.

Use `frontend/map/` or `frontend/common` for angular objects/scripts.