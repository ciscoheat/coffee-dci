(function() {
  var Context, top, _base;

  top = this;

  top.Ivento || (top.Ivento = {});

  (_base = top.Ivento).Dci || (_base.Dci = {});

  top.Ivento.Dci.Context = Context = (function() {

    function Context() {}

    Context.prototype.bind = function(rolePlayer, contextProperty) {
      if (contextProperty == null) {
        contextProperty = 'context';
      }
      return Context.bind(this, rolePlayer, contextProperty);
    };

    Context.prototype.unbind = function(name) {
      if (name == null) {
        name = null;
      }
      return Context.unbind(this, name);
    };

    Context._isObject = function(x) {
      return !!(x !== null && typeof x === 'object');
    };

    Context._isFunction = function(x) {
      return !!(x && x.constructor && x.call && x.apply);
    };

    Context._isRoleObject = function(field) {
      return this._isObject(field);
    };

    Context._isRoleMethod = function(prop, method) {
      return prop[0] !== '_' && prop !== 'constructor' && this._isFunction(method);
    };

    Context.bind = function(context, rolePlayer, contextProperty) {
      var createContextMethod, doBinding, doBindings, field, isContextMethod, prop, proto, roleMethod, roleMethodName, roleMethods, roleName;
      if (contextProperty == null) {
        contextProperty = 'context';
      }
      isContextMethod = function(prop) {
        return prop[0] !== '_' && !(prop === 'constructor' || prop === 'bind' || prop === 'unbind') && Context._isFunction(context[prop]);
      };
      doBinding = function(roleName, rolePlayer) {
        var createRoleMethod, previousRolePlayer, prop, roleMethod, _ref;
        createRoleMethod = function(prop, roleMethod, objectMethod) {
          var method;
          if ((objectMethod != null) && !(roleMethod != null)) {
            return objectMethod;
          }
          if (!(objectMethod != null) && !(roleMethod != null)) {
            throw "No Role method or Object method '" + prop + "' found.";
          }
          if (!(objectMethod != null)) {
            context.__isBound[roleName][prop] = true;
          } else {
            context.__isBound[roleName][prop] = objectMethod;
          }
          method = function() {
            var calledFromContext, caller;
            if (!(objectMethod != null)) {
              return roleMethod.apply(rolePlayer, arguments);
            }
            caller = arguments.callee.caller.__contextMethod;
            calledFromContext = caller === true || caller === roleName;
            if (calledFromContext) {
              return roleMethod.apply(rolePlayer, arguments);
            } else {
              return objectMethod.apply(rolePlayer, arguments);
            }
          };
          method.__context = context;
          return method;
        };
        previousRolePlayer = context.__isBound[roleName].__rolePlayer;
        if ((previousRolePlayer != null) && previousRolePlayer !== rolePlayer) {
          Context.unbind(context, roleName);
        }
        _ref = context.constructor.prototype[roleName];
        for (prop in _ref) {
          roleMethod = _ref[prop];
          if (Context._isRoleMethod(prop, roleMethod)) {
            rolePlayer[prop] = createRoleMethod(prop, roleMethod, rolePlayer[prop]);
          }
        }
        return context[roleName] = rolePlayer;
      };
      doBindings = function() {
        var roleName, _results;
        _results = [];
        for (roleName in context.__isBound) {
          _results.push(doBinding(roleName, context.__isBound[roleName].__rolePlayer));
        }
        return _results;
      };
      createContextMethod = function(prop) {
        return function() {
          var oldContext, output;
          oldContext = rolePlayer[contextProperty];
          rolePlayer[contextProperty] = context;
          doBindings();
          output = null;
          try {
            output = context.constructor.prototype[prop].apply(context, arguments);
            return output;
          } finally {
            if (!((output != null ? output.then : void 0) != null) && !((output != null ? output.done : void 0) != null)) {
              Context.unbind(context);
              if (oldContext === void 0) {
                delete rolePlayer[contextProperty];
              } else {
                rolePlayer[contextProperty] = oldContext;
              }
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
            proto[prop].__contextMethod = true;
          } else if (Context._isRoleObject(field)) {
            roleName = prop;
            for (roleMethodName in field) {
              roleMethod = field[roleMethodName];
              if (!(Context._isRoleMethod(roleMethodName, roleMethod))) {
                continue;
              }
              proto[prop][roleMethodName].__contextMethod = roleName;
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
          }
        }
      }
      return {
        to: function(role) {
          var _i, _len, _ref;
          roleName = null;
          for (prop in context) {
            field = context[prop];
            if (field === role) {
              roleName = prop;
              break;
            }
          }
          if (!roleName) {
            throw "Role for RolePlayer not found in Context.";
          }
          if (role._contract != null) {
            _ref = role._contract;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              prop = _ref[_i];
              if (!(prop in rolePlayer)) {
                throw "RolePlayer " + rolePlayer + " didn't fulfill Role Contract with property '" + prop + "'.";
              }
            }
          }
          return context.__isBound[roleName] = {
            __rolePlayer: rolePlayer
          };
        }
      };
    };

    Context.unbind = function(context, name) {
      var roleName, unbindMethods, _results;
      if (name == null) {
        name = null;
      }
      unbindMethods = function(name) {
        var field, prop, rp, _ref;
        rp = context.__isBound[name].__rolePlayer;
        _ref = context.__isBound[name];
        for (prop in _ref) {
          field = _ref[prop];
          if (prop !== '__rolePlayer') {
            if (field === true) {
              delete rp[prop];
            } else {
              rp[prop] = field;
            }
          }
        }
        return context.__isBound[name] = {
          __rolePlayer: rp
        };
      };
      if (!(name != null)) {
        _results = [];
        for (roleName in context.__isBound) {
          _results.push(unbindMethods(roleName));
        }
        return _results;
      } else {
        return unbindMethods(name);
      }
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
