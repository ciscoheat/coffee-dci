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
      var cacheName;
      cacheName = "__methodCache";
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
          assignRoleMethod = function(prop) {
            if (role.hasOwnProperty(prop)) {
              if (rolePlayer.hasOwnProperty(prop)) {
                rolePlayer[cacheName] || (rolePlayer[cacheName] = {});
                rolePlayer[cacheName][prop] = rolePlayer[prop];
              }
              return rolePlayer[prop] = applyRoleMethod(prop);
            }
          };
          for (prop in role) {
            field = role[prop];
            assignRoleMethod(prop);
          }
          if (rolePlayer.hasOwnProperty('context')) {
            rolePlayer[cacheName] || (rolePlayer[cacheName] = {});
            rolePlayer[cacheName]['context'] = rolePlayer['context'];
          }
          rolePlayer['context'] = context;
          unbind = rolePlayer.unbind;
          if (unbind) {
            cache.unbind = unbind;
          }
          rolePlayer.unbind = function() {
            prop = void 0;
            cache = rolePlayer[cacheName];
            for (prop in role) {
              field = role[prop];
              if (role.hasOwnProperty(prop) && rolePlayer.hasOwnProperty(prop)) {
                delete rolePlayer[prop];
              }
            }
            delete rolePlayer.unbind;
            if (cache) {
              for (prop in cache) {
                field = cache[prop];
                rolePlayer[prop] = cache[prop];
              }
            }
            return context[roleName] = context.prototype[roleName];
          };
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
