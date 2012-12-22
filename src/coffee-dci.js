(function() {
  var Context, top, _base;

  top = typeof exports !== "undefined" && exports !== null ? exports : window;

  top.Ivento || (top.Ivento = {});

  (_base = top.Ivento).Dci || (_base.Dci = {});

  top.Ivento.Dci.Context = Context = (function() {

    function Context(__contextProperty) {
      this.__contextProperty = __contextProperty;
    }

    Context.prototype.bind = function(rolePlayer) {
      return Context.bind(this, rolePlayer, this.__contextProperty);
    };

    Context.isFunction = function(obj) {
      return !!(obj && obj.constructor && obj.call && obj.apply);
    };

    Context.isObject = function(obj) {
      return obj !== null && typeof obj === 'object';
    };

    Context.bind = function(context, rolePlayer, contextProperty) {
      var contextCache, rolePlayerCacheId, _base1;
      if (contextProperty == null) {
        contextProperty = 'context';
      }
      context.__contextCacheId || (context.__contextCacheId = 0);
      rolePlayerCacheId = ++context.__contextCacheId;
      context.__contextCache || (context.__contextCache = {});
      (_base1 = context.__contextCache)[rolePlayerCacheId] || (_base1[rolePlayerCacheId] = {});
      contextCache = context.__contextCache;
      return {
        to: function(role) {
          var applyRoleMethod, assignRoleMethod, cacheFor, contextIsBound, contextRole, decorateContextMethods, field, isValidContextProperty, prop, roleProperty, setCacheFor, _i, _len, _ref;
          roleProperty = null;
          for (prop in context) {
            field = context[prop];
            if (field === role) {
              roleProperty = prop;
              context[prop] = rolePlayer;
              break;
            }
          }
          if (!roleProperty) {
            throw "Role for RolePlayer not found in Context.";
          }
          cacheFor = function(prop) {
            if (!(contextCache[rolePlayerCacheId] != null)) {
              throw "Object for " + rolePlayer + " not found in context cache.";
            }
            return contextCache[rolePlayerCacheId][prop];
          };
          setCacheFor = function(prop, value) {
            return contextCache[rolePlayerCacheId][prop] = value;
          };
          isValidContextProperty = function(obj, prop) {
            return prop !== 'constructor' && prop !== '_contract' && obj.hasOwnProperty(prop);
          };
          contextIsBound = function() {
            return context.unbind != null;
          };
          contextRole = function() {
            return context.constructor.prototype[roleProperty];
          };
          decorateContextMethods = function(obj, roleMethods) {
            var _results;
            _results = [];
            for (prop in obj) {
              field = obj[prop];
              if (isValidContextProperty(obj, prop)) {
                if (!field.__contextMethod && Context.isFunction(field)) {
                  _results.push(field.__contextMethod = roleMethods ? roleProperty : true);
                } else if (prop === roleProperty) {
                  _results.push(decorateContextMethods(field, true));
                } else {
                  _results.push(void 0);
                }
              }
            }
            return _results;
          };
          applyRoleMethod = function(prop) {
            return function() {
              var contextCaller, method, objectMethod;
              objectMethod = cacheFor(prop);
              contextCaller = arguments.callee.caller.__contextMethod;
              if (!objectMethod || contextCaller === true || contextCaller === roleProperty) {
                method = role[prop];
              } else {
                method = objectMethod;
              }
              return method.apply(rolePlayer, arguments);
            };
          };
          assignRoleMethod = function(prop, value) {
            var cache;
            if (value == null) {
              value = null;
            }
            cache = rolePlayer.hasOwnProperty(prop) ? rolePlayer[prop] : false;
            setCacheFor(prop, cache);
            return rolePlayer[prop] = value != null ? value : applyRoleMethod(prop);
          };
          if (role._contract != null) {
            _ref = role._contract;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              prop = _ref[_i];
              if (!(prop in rolePlayer)) {
                throw "RolePlayer " + rolePlayer + " didn't fulfill Role Contract with property '" + prop + "'.";
              }
            }
          }
          decorateContextMethods(context.constructor.prototype, false);
          for (prop in role) {
            field = role[prop];
            if (isValidContextProperty(role, prop)) {
              assignRoleMethod(prop);
            }
          }
          assignRoleMethod(contextProperty, context);
          if (!contextIsBound()) {
            return context.unbind = function() {
              var cache, id;
              for (id in contextCache) {
                for (prop in contextCache[id]) {
                  cache = contextCache[id][prop];
                  if (cache) {
                    rolePlayer[prop] = cache;
                  } else {
                    delete rolePlayer[prop];
                  }
                }
              }
              context[roleProperty] = context.constructor.prototype[roleProperty];
              return delete context.unbind;
            };
          }
        }
      };
    };

    return Context;

  })();

}).call(this);
