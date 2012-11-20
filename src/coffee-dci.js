(function() {
  var Context, top, _base;

  top = typeof exports !== "undefined" && exports !== null ? exports : window;

  top.Ivento || (top.Ivento = {});

  (_base = top.Ivento).Dci || (_base.Dci = {});

  top.Ivento.Dci.Context = Context = (function() {

    function Context() {}

    Context.prototype.bind = function(rolePlayer) {
      var cacheName, context;
      context = this;
      cacheName = "__methodCache";
      return {
        to: function(role) {
          var applyRoleMethod, cache, field, prop, roleName, unbind;
          cache = null;
          unbind = null;
          roleName = null;
          applyRoleMethod = function(name) {
            return function() {
              return role[name].apply(rolePlayer, arguments);
            };
          };
          for (prop in role) {
            field = role[prop];
            if (role.hasOwnProperty(prop)) {
              if (rolePlayer.hasOwnProperty(prop)) {
                rolePlayer[cacheName] || (rolePlayer[cacheName] = {});
                rolePlayer[cacheName][prop] = rolePlayer[prop];
              }
              rolePlayer[prop] = applyRoleMethod(prop);
            }
          }
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
