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

    Context.setPromiseAdapter = function(settings) {
      Context.promise = settings.factory;
      Context.unbindPromise = settings.unbind;
      return Context.isPromise = settings.identify;
    };

    Context.promise = function() {
      return new top.promise.Promise();
    };

    Context.unbindPromise = function(p, f) {
      return p.then(f);
    };

    Context.isPromise = function(p) {
      return (p.then != null) && (p.done != null);
    };

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
      var bindingFor, createContextMethod, doBinding, doBindings, field, isContextMethod, prop, proto, roleMethod, roleMethodName, roleMethods, roleName, unbindContext;
      isContextMethod = function(prop) {
        return prop[0] !== '_' && !(prop === 'constructor' || prop === 'bind' || prop === 'unbind') && Context._isFunction(context[prop]);
      };
      bindingFor = function(roleName) {
        return Context._bindingFor(context, roleName);
      };
      doBinding = function(contextMethodName, roleName) {
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
          player.promise = context[contextMethodName].__promise;
        }
        return context[roleName] = player;
      };
      doBindings = function(contextMethodName) {
        var roleName, _results;
        _results = [];
        for (roleName in context.__isBound) {
          _results.push(doBinding(contextMethodName, roleName));
        }
        return _results;
      };
      unbindContext = function(context, oldPromise) {
        Context.unbind(context);
        if (oldPromise === void 0) {
          return delete context.promise;
        } else {
          return context.promise = oldPromise;
        }
      };
      createContextMethod = function(contextMethodName) {
        return function() {
          var oldPromise, output, unbind, _base1;
          oldPromise = context.promise;
          (_base1 = context[contextMethodName]).__promise || (_base1.__promise = Context.promise());
          context.promise = context[contextMethodName].__promise;
          doBindings(contextMethodName);
          output = null;
          try {
            output = context.constructor.prototype[contextMethodName].apply(context, arguments);
            return output;
          } finally {
            unbind = function() {
              return unbindContext(context, oldPromise);
            };
            if ((output != null) && Context.isPromise(output)) {
              Context.unbindPromise(output, unbind);
            } else {
              unbind();
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
        var binding, contextProperty, field, oldContext, oldPromise, prop, rolePlayer;
        binding = Context._bindingFor(context, role);
        rolePlayer = binding.__rolePlayer;
        contextProperty = binding.__contextProperty;
        if (rolePlayer === null) {
          return;
        }
        for (prop in binding) {
          field = binding[prop];
          if (prop[0] !== '_') {
            if (field === true) {
              delete rolePlayer[prop];
            } else {
              rolePlayer[prop] = field;
            }
          }
        }
        oldContext = binding.__oldContext;
        if (oldContext === void 0) {
          delete rolePlayer[contextProperty];
        } else {
          rolePlayer[contextProperty] = oldContext;
        }
        oldPromise = binding.__oldPromise;
        if (oldPromise === void 0) {
          delete rolePlayer.promise;
        } else {
          rolePlayer.promise = oldPromise;
        }
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

  
/*
 *  Copyright 2012 (c) Pierre Duquesne <stackp@online.fr>
 *  Licensed under the New BSD License.
 *  https://github.com/stackp/promisejs
 */
if(this.promise == null) {
(function(a){function b(a,b){return function(){return a.apply(b,arguments);};}function c(){this._callbacks=[];}c.prototype.then=function(a,c){var d=b(a,c);if(this._isdone)d(this.error,this.result);else this._callbacks.push(d);};c.prototype.done=function(a,b){this._isdone=true;this.error=a;this.result=b;for(var c=0;c<this._callbacks.length;c++)this._callbacks[c](a,b);this._callbacks=[];};function d(a){var b=a.length;var d=0;var e=new c();var f=[];var g=[];function h(a){return function(c,h){d+=1;f[a]=c;g[a]=h;if(d===b)e.done(f,g);};}for(var i=0;i<b;i++)a[i]().then(h(i));return e;}function e(a,b,d){var f=new c();if(a.length===0)f.done(b,d);else a[0](b,d).then(function(b,c){a.splice(0,1);e(a,b,c).then(function(a,b){f.done(a,b);});});return f;}function f(a){var b="";if(typeof a==="string")b=a;else{var c=encodeURIComponent;for(var d in a)if(a.hasOwnProperty(d))b+='&'+c(d)+'='+c(a[d]);}return b;}function g(){var a;if(window.XMLHttpRequest)a=new XMLHttpRequest();else if(window.ActiveXObject)try{a=new ActiveXObject("Msxml2.XMLHTTP");}catch(b){a=new ActiveXObject("Microsoft.XMLHTTP");}return a;}function h(a,b,d,e){var h=new c();var i,j;d=d||{};e=e||{};try{i=g();}catch(k){h.done(-1,"");return h;}j=f(d);if(a==='GET'&&j){b+='?'+j;j=null;}i.open(a,b);i.setRequestHeader('Content-type','application/x-www-form-urlencoded');for(var l in e)if(e.hasOwnProperty(l))i.setRequestHeader(l,e[l]);i.onreadystatechange=function(){if(i.readyState===4)if(i.status===200)h.done(null,i.responseText);else h.done(i.status,"");};i.send(j);return h;}function i(a){return function(b,c,d){return h(a,b,c,d);};}var j={Promise:c,join:d,chain:e,ajax:h,get:i('GET'),post:i('POST'),put:i('PUT'),del:i('DELETE')};if(typeof define==='function'&&define.amd)define(function(){return j;});else a.promise=j;})(this);
}
;


}).call(this);
