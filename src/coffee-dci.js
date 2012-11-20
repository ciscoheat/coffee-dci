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

    Context.bind = function(context, rolePlayer, contextProperty) {
      var _base1;
      if (contextProperty == null) {
        contextProperty = 'context';
      }
      context.__contextCache || (context.__contextCache = {});
      (_base1 = context.__contextCache)[rolePlayer] || (_base1[rolePlayer] = {});
      return {
        to: function(role) {
          var applyRoleMethod, assignRoleMethod, cache, field, prop, roleName, unbind;
          cache = null;
          unbind = null;
          roleName = null;
          applyRoleMethod = function(name) {
            return function() {
              return role[name].apply(rolePlayer, arguments);
            };
          };
          assignRoleMethod = function(prop, value) {
            if (value == null) {
              value = null;
            }
            cache = rolePlayer.hasOwnProperty(prop) ? rolePlayer[prop] : false;
            context.__contextCache[rolePlayer][prop] = cache;
            return rolePlayer[prop] = value != null ? value : applyRoleMethod(prop);
          };
          for (prop in role) {
            field = role[prop];
            if (role.hasOwnProperty(prop)) {
              assignRoleMethod(prop);
            }
          }
          assignRoleMethod(contextProperty, context);
          if (!(context.unbind != null)) {
            context.unbind = function() {
              var player;
              for (player in context.__contextCache) {
                for (prop in context.__contextCache[player]) {
                  cache = context.__contextCache[player][prop];
                  if (cache) {
                    rolePlayer[prop] = cache;
                  } else {
                    delete rolePlayer[prop];
                  }
                }
              }
              context[roleName] = context.constructor.prototype[roleName];
              return delete context.unbind;
            };
          }
          for (prop in context) {
            field = context[prop];
            if (field === role) {
              roleName = prop;
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
