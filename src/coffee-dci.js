(function() {
  var Context, top, _base;

  top = this;

  top.Ivento || (top.Ivento = {});

  (_base = top.Ivento).Dci || (_base.Dci = {});

  top.Ivento.Dci.Context = Context = (function() {

    function Context() {}

    Context.prototype.bind = function(rolePlayer) {
      return Context.bind(this, rolePlayer);
    };

    Context.prototype.unbind = function(name) {
      if (name == null) {
        name = null;
      }
      return Context.unbind(this, name);
    };

    Context.promiseJsAdapter = {
      factory: function() {
        return new promise.Promise();
      },
      unbind: function(p, f) {
        return p.then(f);
      },
      identify: function(p) {
        return (p.then != null) && (p.done != null);
      }
    };

    Context.jQueryAdapter = {
      factory: function() {
        return jQuery.Deferred();
      },
      unbind: function(p, f) {
        return p.always(f);
      },
      identify: function(p) {
        return (p.always != null) && (p.done != null) && (p.fail != null);
      }
    };

    Context.setPromiseAdapter = function(settings) {
      Context.promise = settings.factory;
      Context.unbindPromise = settings.unbind;
      return Context.isPromise = settings.identify;
    };

    Context.promise = function() {
      return null;
    };

    Context.unbindPromise = function(p, f) {};

    Context.isPromise = function(p) {
      return false;
    };

    if (typeof jQuery !== "undefined" && jQuery !== null) {
      Context.setPromiseAdapter(Context.jQueryAdapter);
    } else if (typeof promise !== "undefined" && promise !== null) {
      Context.setPromiseAdapter(Context.promiseJsAdapter);
    }

    Context._isObject = function(x) {
      return !!(x !== null && typeof x === 'object');
    };

    Context._isFunction = function(x) {
      return !!(x && x.constructor && x.call && x.apply);
    };

    Context._isRoleObject = function(prop, field) {
      return prop[0] !== '_' && this._isObject(field);
    };

    Context._isRoleMethod = function(prop, method) {
      return prop[0] !== '_' && prop !== 'constructor' && this._isFunction(method);
    };

    Context.bind = function(context, rolePlayer) {
      var bindContext, bindingFor, createContextMethod, doBinding, field, isContextMethod, prop, proto, roleMethod, roleMethodName, roleMethods, roleName, unbindContext;
      isContextMethod = function(prop) {
        return prop[0] !== '_' && !(prop === 'constructor' || prop === 'bind' || prop === 'unbind') && Context._isFunction(context[prop]);
      };
      bindingFor = function(roleName) {
        return Context._bindingFor(context, roleName);
      };
      doBinding = function(roleName) {
        var binding, createRoleMethod, player, prop, roleMethod, _ref;
        binding = bindingFor(roleName);
        player = binding.__rolePlayer;
        createRoleMethod = function(prop) {
          var objectMethod, roleMethod;
          objectMethod = player[prop];
          roleMethod = context.constructor.prototype[roleName][prop];
          if ((objectMethod != null) && !(roleMethod != null)) {
            return objectMethod;
          }
          if (!(objectMethod != null) && !(roleMethod != null)) {
            throw "No Role method or Object method '" + prop + "' found.";
          }
          if (!(objectMethod != null)) {
            binding[prop] = true;
          } else {
            binding[prop] = objectMethod;
          }
          return function() {
            var calledFromContext, caller;
            if (!(objectMethod != null)) {
              return roleMethod.apply(player, arguments);
            }
            caller = arguments.callee.caller.__inContext;
            calledFromContext = caller === true || caller === roleName;
            if (calledFromContext) {
              return roleMethod.apply(player, arguments);
            } else {
              return objectMethod.apply(player, arguments);
            }
          };
        };
        if (player !== null) {
          _ref = context.constructor.prototype[roleName];
          for (prop in _ref) {
            roleMethod = _ref[prop];
            if (Context._isRoleMethod(prop, roleMethod)) {
              player[prop] = createRoleMethod(prop);
            }
          }
          binding.__oldContext = player[binding.__contextProperty];
          binding.__oldPromise = player.promise;
          player[binding.__contextProperty] = context;
          player.promise = context.promise;
        }
        return context[roleName] = player;
      };
      bindContext = function() {
        var roleName, _results;
        context.__oldPromise = context.promise;
        context.promise = Context.promise();
        _results = [];
        for (roleName in context.__isBound) {
          _results.push(doBinding(roleName));
        }
        return _results;
      };
      unbindContext = function(context, oldPromise) {
        Context.unbind(context);
        if (!(context.__oldPromise != null)) {
          return delete context.promise;
        } else {
          return context.promise = context.__oldPromise;
        }
      };
      createContextMethod = function(contextMethodName) {
        return function() {
          var output, unbindContextMethod;
          bindContext();
          output = null;
          try {
            output = context.constructor.prototype[contextMethodName].apply(context, arguments);
            return output;
          } finally {
            unbindContextMethod = function() {
              return unbindContext(context);
            };
            if ((output != null) && Context.isPromise(output)) {
              Context.unbindPromise(output, unbindContextMethod);
            } else {
              unbindContextMethod();
            }
          }
        };
      };
      proto = context.constructor.prototype;
      if (!(proto.__isProtoBound != null)) {
        proto.__isProtoBound = true;
        roleMethods = {};
        for (prop in proto) {
          field = proto[prop];
          if (isContextMethod(prop)) {
            proto[prop].__inContext = true;
          } else if (Context._isRoleObject(prop, field)) {
            roleName = prop;
            for (roleMethodName in field) {
              roleMethod = field[roleMethodName];
              if (!(Context._isRoleMethod(roleMethodName, roleMethod))) {
                continue;
              }
              proto[prop][roleMethodName].__inContext = roleName;
              if (roleMethods[roleMethodName] != null) {
                throw "Method name conflict in Roles '" + roleMethods[roleMethodName] + "' and '" + roleName + "." + roleMethodName + "'. Please prepend the Role names to the methods to avoid conflict.";
              } else {
                roleMethods[roleMethodName] = roleName + "." + roleMethodName;
              }
            }
          }
        }
      }
      if (!(context.__isBound != null)) {
        context.__isBound = {};
        proto = context.constructor.prototype;
        for (prop in proto) {
          field = proto[prop];
          if (isContextMethod(prop)) {
            context[prop] = createContextMethod(prop);
          } else if (Context._isRoleObject(prop, field)) {
            context[prop] = {};
          }
        }
      }
      return {
        to: function(role, contextProperty) {
          var current, fields, prevBinding, roleProto, _i, _len, _ref;
          if (contextProperty == null) {
            contextProperty = 'context';
          }
          if (!(typeof role === 'string')) {
            throw "A Role must be bound as a string literal.";
          }
          if (!(role in context)) {
            throw "Role '" + role + "' not found in Context.";
          }
          roleProto = context.constructor.prototype[role];
          if (rolePlayer !== null && (roleProto._contract != null)) {
            _ref = roleProto._contract;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              prop = _ref[_i];
              fields = prop.split(".");
              current = rolePlayer;
              while (fields.length) {
                current = current[fields.shift()];
                if (current === void 0) {
                  throw "RolePlayer " + rolePlayer + " didn't fulfill Role Contract with property '" + prop + "'.";
                }
              }
            }
          }
          prevBinding = bindingFor(role);
          if ((prevBinding != null) && (prevBinding.__rolePlayer != null) && prevBinding.__rolePlayer !== rolePlayer) {
            Context.unbind(context, role);
          }
          return context.__isBound[role] = Context._defaultBinding(rolePlayer, contextProperty);
        }
      };
    };

    Context.unbind = function(context, name) {
      var role, unbindMethods, _results;
      if (name == null) {
        name = null;
      }
      unbindMethods = function(role) {
        var binding, contextProperty, field, prop, restore, rolePlayer;
        binding = Context._bindingFor(context, role);
        rolePlayer = binding.__rolePlayer;
        contextProperty = binding.__contextProperty;
        if (rolePlayer === null) {
          return;
        }
        restore = function(obj, prop, oldValue, deleteField) {
          if (oldValue === deleteField) {
            return delete obj[prop];
          } else {
            return obj[prop] = oldValue;
          }
        };
        for (prop in binding) {
          field = binding[prop];
          if (prop[0] !== '_') {
            restore(rolePlayer, prop, field, true);
          }
        }
        restore(rolePlayer, contextProperty, binding.__oldContext);
        restore(rolePlayer, 'promise', binding.__oldPromise);
        context.__isBound[role] = Context._defaultBinding(rolePlayer, contextProperty);
        return context[role] = {};
      };
      if (!(name != null)) {
        _results = [];
        for (role in context.__isBound) {
          _results.push(unbindMethods(role));
        }
        return _results;
      } else {
        return unbindMethods(name);
      }
    };

    Context._bindingFor = function(context, role) {
      return context.__isBound[role];
    };

    Context._defaultBinding = function(rolePlayer, contextProperty) {
      return {
        __rolePlayer: rolePlayer,
        __oldContext: null,
        __oldPromise: null,
        __contextProperty: contextProperty
      };
    };

    return Context;

  })();

}).call(this);
