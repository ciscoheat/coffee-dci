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
          var applyRoleMethod, assignRoleMethod, cacheFor, contextIsBound, decorateContextMethods, field, isValidContextProperty, prop, roleMethod, setCacheFor, _i, _len, _ref;
          roleMethod = null;
          if (role._contract != null) {
            _ref = role._contract;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              prop = _ref[_i];
              if (!(prop in rolePlayer)) {
                throw "RolePlayer " + rolePlayer + " didn't fulfill Role Contract with property '" + prop + "'.";
              }
            }
          }
          cacheFor = function(prop) {
            if (!(contextCache[rolePlayerCacheId] != null)) {
              if ((typeof console !== "undefined" && console !== null ? console.log : void 0) != null) {
                console.log("Object not found in context cache:");
                console.log(rolePlayer);
                console.log("Cache:");
                console.log(contextCache);
                console.log("==========");
              }
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
          decorateContextMethods = function(obj) {
            var field, _results;
            _results = [];
            for (prop in obj) {
              field = obj[prop];
              if (isValidContextProperty(obj, prop)) {
                if (Context.isFunction(field)) {
                  _results.push(field.__contextMethod = true);
                } else if (Context.isObject(field)) {
                  _results.push(decorateContextMethods(field));
                } else {
                  _results.push(void 0);
                }
              }
            }
            return _results;
          };
          applyRoleMethod = function(prop) {
            return function() {
              var callingMethod, method, objectMethod;
              objectMethod = cacheFor(prop);
              callingMethod = arguments.callee.caller;
              if (!objectMethod || (callingMethod.__contextMethod != null)) {
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
          if (!contextIsBound()) {
            decorateContextMethods(context.constructor.prototype);
          }
          for (prop in role) {
            field = role[prop];
            if (isValidContextProperty(role, prop)) {
              assignRoleMethod(prop);
            }
          }
          assignRoleMethod(contextProperty, context);
          if (!contextIsBound()) {
            context.unbind = function() {
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
              context[roleMethod] = context.constructor.prototype[roleMethod];
              return delete context.unbind;
            };
          }
          for (prop in context) {
            field = context[prop];
            if (field === role) {
              roleMethod = prop;
              context[prop] = rolePlayer;
              return;
            }
          }
          throw "Role for RolePlayer not found in Context.";
        }
      };
    };

    return Context;

  })();

}).call(this);
