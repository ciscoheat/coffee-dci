(function() {
  var Context, top, _base;

  top = typeof exports !== "undefined" && exports !== null ? exports : window;

  top.Ivento || (top.Ivento = {});

  (_base = top.Ivento).Dci || (_base.Dci = {});

  top.Ivento.Dci.Context = Context = (function() {

    function Context() {}

    Context.prototype.bind = function(rolePlayer) {
      return Context.bind(this, rolePlayer);
    };

    Context.bind = function(context, rolePlayer) {
      var createContextMethod, field, isContextMethod, isFunction, isObject, isRoleMethod, isRoleObject, prop, roleMethod, roleName, _ref;
      isFunction = function(x) {
        return !!(x && x.constructor && x.call && x.apply);
      };
      isObject = function(x) {
        return x !== null && typeof x === 'object';
      };
      isRoleObject = function(field) {
        return isObject(field);
      };
      isContextMethod = function(prop) {
        return prop[0] !== '_' && prop !== 'constructor' && isFunction(context[prop]);
      };
      isRoleMethod = function(prop, method) {
        return prop[0] !== '_' && prop !== 'constructor' && isFunction(method);
      };
      createContextMethod = function(prop) {
        return function() {
          var prevContext;
          prevContext = Context.__current;
          Context.__current = context;
          try {
            return context.constructor.prototype[prop].apply(context, arguments);
          } finally {
            Context.__current = prevContext;
          }
        };
      };
      if (!(context.__methodBound != null)) {
        context.__methodBound = true;
        _ref = context.constructor.prototype;
        for (prop in _ref) {
          field = _ref[prop];
          if (isContextMethod(prop)) {
            context.constructor.prototype[prop].__contextMethod = true;
            context[prop] = createContextMethod(prop);
          } else if (isRoleObject(field)) {
            for (roleName in field) {
              roleMethod = field[roleName];
              if (isRoleMethod(roleName, roleMethod)) {
                context.constructor.prototype[prop][roleName].__contextMethod = prop;
              }
            }
          }
        }
      }
      return {
        to: function(role, contextProperty) {
          var createRoleMethod, objectMethod, roleKeys, rolePlayerType, roleProp, _i, _j, _len, _len1, _ref1, _ref2, _results;
          if (contextProperty == null) {
            contextProperty = 'context';
          }
          roleProp = null;
          for (prop in context) {
            field = context[prop];
            if (field === role) {
              roleProp = prop;
              break;
            }
          }
          if (!roleProp) {
            throw "Role for RolePlayer not found in Context.";
          }
          if (role._contract != null) {
            _ref1 = role._contract;
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              prop = _ref1[_i];
              if (!(prop in rolePlayer)) {
                throw "RolePlayer " + rolePlayer + " didn't fulfill Role Contract with property '" + prop + "'.";
              }
            }
          }
          roleKeys = function() {
            var keys;
            keys = (function() {
              var _ref2, _results;
              _ref2 = context.constructor.prototype[roleProp];
              _results = [];
              for (prop in _ref2) {
                field = _ref2[prop];
                if (isRoleMethod(prop, field)) {
                  _results.push(prop);
                }
              }
              return _results;
            })();
            if (role._contract != null) {
              keys = keys.concat(role._contract);
            }
            return keys;
          };
          createRoleMethod = function(prop, roleMethod, objectMethod) {
            return function() {
              var calledFromContext, caller, oldContext;
              oldContext = rolePlayer[contextProperty];
              rolePlayer[contextProperty] = Context.__current;
              caller = arguments.callee.caller.__contextMethod;
              calledFromContext = caller === true || caller === roleProp;
              try {
                if ((roleMethod != null) && !(objectMethod != null)) {
                  return context.constructor.prototype[roleProp][prop].apply(rolePlayer, arguments);
                }
                if ((objectMethod != null) && !(roleMethod != null)) {
                  return objectMethod.apply(rolePlayer, arguments);
                }
                if (roleMethod && objectMethod) {
                  if (calledFromContext) {
                    return context.constructor.prototype[roleProp][prop].apply(rolePlayer, arguments);
                  } else {
                    return objectMethod.apply(rolePlayer, arguments);
                  }
                }
                throw "No Role Method or Object Method '" + prop + "' found.";
              } finally {
                if (oldContext != null) {
                  rolePlayer[contextProperty] = oldContext;
                } else {
                  delete rolePlayer[contextProperty];
                }
              }
            };
          };
          rolePlayerType = typeof rolePlayer;
          context[roleProp] = rolePlayerType === 'boolean' || rolePlayerType === 'number' || rolePlayerType === 'string' ? rolePlayer : {};
          _ref2 = roleKeys();
          _results = [];
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            prop = _ref2[_j];
            roleMethod = context.constructor.prototype[roleProp][prop];
            objectMethod = rolePlayer[prop];
            context[roleProp][prop] = createRoleMethod(prop, roleMethod, objectMethod);
            if (roleMethod && objectMethod) {
              _results.push(rolePlayer[prop] = context[roleProp][prop]);
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        }
      };
    };

    return Context;

  })();

}).call(this);
