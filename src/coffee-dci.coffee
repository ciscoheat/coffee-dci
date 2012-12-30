# Namespace assignment
top = this
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	bind: (rolePlayer, contextProperty = 'context') -> Context.bind @, rolePlayer, contextProperty
	unbind: (name = null) -> Context.unbind @, name

	@promise: () -> new top.promise.Promise()
	@unbindPromise: (p) -> p.then
	@isPromise: (p) -> p.then? and p.done?

	@_isObject: (x) -> !!(x isnt null and typeof x is 'object')
	@_isFunction: (x) -> !!(x && x.constructor && x.call && x.apply)
	@_isRoleObject: (field) -> @_isObject field
	@_isRoleMethod: (prop, method) -> prop[0] isnt '_' and prop isnt 'constructor' and @._isFunction(method)

	@bind: (context, rolePlayer, contextProperty = 'context') ->		
		
		isContextMethod = (prop) -> 
			prop[0] isnt '_' and 
			not (prop in ['constructor', 'bind', 'unbind', 'promise']) and 
			Context._isFunction(context[prop])

		doBinding = (roleName, rolePlayer) ->

			createRoleMethod = (prop, roleMethod, objectMethod) ->
				# If only Object Method is available, nothing changes
				return objectMethod if objectMethod? and not roleMethod?

				throw "No Role method or Object method '" + prop + "' found." if not objectMethod? and not roleMethod?

				if not objectMethod?
					context.__isBound[roleName][prop] = true
				else
					context.__isBound[roleName][prop] = objectMethod

				method = ->	

					# If only Role Method is available, call it.						
					return roleMethod.apply rolePlayer, arguments if not objectMethod?

					# If both Role and Object Method is available, determine if method was called
					# from a Context, and call Role Method if so, if not call Object Method.
					caller = arguments.callee.caller.__contextMethod
					calledFromContext = caller is true or caller is roleName

					if calledFromContext
						return roleMethod.apply rolePlayer, arguments
					else
						return objectMethod.apply rolePlayer, arguments # rolePlayer or this?

				# Set context so it can be used in the Role Methods "context" method
				method.__context = context
				method

			# If rebinding roles, unbind the current.
			previousRolePlayer = context.__isBound[roleName].__rolePlayer
			Context.unbind context, roleName if previousRolePlayer? and previousRolePlayer isnt rolePlayer

			for prop, roleMethod of context.constructor.prototype[roleName] when Context._isRoleMethod prop, roleMethod
				rolePlayer[prop] = createRoleMethod prop, roleMethod, rolePlayer[prop]

			# Assign RolePlayer to Role
			context[roleName] = rolePlayer

		doBindings = () ->
			doBinding roleName, context.__isBound[roleName].__rolePlayer for roleName of context.__isBound				

		createContextMethod = (prop) ->
			-> 
				oldContext = rolePlayer[contextProperty]
				oldPromise = context.promise

				# Set the current context and create a promise that can be used in
				# asynchronous operations.
				rolePlayer[contextProperty] = context

				if not context.promise? or not Context.isPromise(context.promise)
					context.promise = Context.promise()
					Context.unbindPromise(context.promise).call context.promise, -> Context.unbind context

				doBindings()

				output = null
				try
					output = context.constructor.prototype[prop].apply context, arguments
					output

				finally
					if not output? or not Context.isPromise output
						Context.unbind context

						if oldContext is undefined
							delete rolePlayer[contextProperty]
						else
							rolePlayer[contextProperty] = oldContext

						if oldPromise isnt context.promise
							if oldPromise is undefined
								delete context.promise
							else
								context.promise = oldPromise

		# Bind Context and Role methods to current context,
		# to determine if the Context or the Object method should be called.
		proto = context.constructor.prototype

		if not proto.__isProtoBound?
			proto.__isProtoBound = true
			roleMethods = {}
			for prop, field of proto
				if isContextMethod prop
					# Context methods should always use the Role Method (true)
					proto[prop].__contextMethod = true
				else if Context._isRoleObject field
					roleName = prop
					for roleMethodName, roleMethod of field when Context._isRoleMethod roleMethodName, roleMethod
						# Role methods should be used in the same Role (Role name)
						proto[prop][roleMethodName].__contextMethod = roleName

						# Test for Role Method conflicts
						if roleMethods[roleMethodName]?
							throw "Method name conflict in Roles '" + roleMethods[roleMethodName] + "' and '" + 
							roleName + "." + roleMethodName + "'. Please prepend the Role names to the methods to avoid conflict."
						else
							roleMethods[roleMethodName] = roleName + "." + roleMethodName

		if not context.__isBound?
			context.__isBound = {}
			proto = context.constructor.prototype
			for prop, field of proto when isContextMethod prop
				context[prop] = createContextMethod prop

		# Return the 'to' method to complete the binding.
		to: (role) ->

			roleName = null

			# Test if Role exists in Context
			for prop, field of context
				if field is role 
					roleName = prop
					break

			throw "Role for RolePlayer not found in Context." if not roleName

			# Test if RolePlayer fulfills Role Contract
			if role._contract?
				for prop in role._contract
					throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract with property '"+prop+"'." if not (prop of rolePlayer)						

			context.__isBound[roleName] = __rolePlayer: rolePlayer

	@unbind: (context, name = null) ->
		unbindMethods = (name) ->
			rp = context.__isBound[name].__rolePlayer
			for prop, field of context.__isBound[name] when prop isnt '__rolePlayer'
				if field is true
					delete rp[prop]
				else
					rp[prop] = field

			context.__isBound[name] = __rolePlayer: rp
		
		if not name?
			unbindMethods roleName for roleName of context.__isBound
		else
			unbindMethods name


# ===== PromiseJS ========================
`
/*
 *  Copyright 2012 (c) Pierre Duquesne <stackp@online.fr>
 *  Licensed under the New BSD License.
 *  https://github.com/stackp/promisejs
 */
if(this.promise == null) {
(function(a){function b(a,b){return function(){return a.apply(b,arguments);};}function c(){this._callbacks=[];}c.prototype.then=function(a,c){var d=b(a,c);if(this._isdone)d(this.error,this.result);else this._callbacks.push(d);};c.prototype.done=function(a,b){this._isdone=true;this.error=a;this.result=b;for(var c=0;c<this._callbacks.length;c++)this._callbacks[c](a,b);this._callbacks=[];};function d(a){var b=a.length;var d=0;var e=new c();var f=[];var g=[];function h(a){return function(c,h){d+=1;f[a]=c;g[a]=h;if(d===b)e.done(f,g);};}for(var i=0;i<b;i++)a[i]().then(h(i));return e;}function e(a,b,d){var f=new c();if(a.length===0)f.done(b,d);else a[0](b,d).then(function(b,c){a.splice(0,1);e(a,b,c).then(function(a,b){f.done(a,b);});});return f;}function f(a){var b="";if(typeof a==="string")b=a;else{var c=encodeURIComponent;for(var d in a)if(a.hasOwnProperty(d))b+='&'+c(d)+'='+c(a[d]);}return b;}function g(){var a;if(window.XMLHttpRequest)a=new XMLHttpRequest();else if(window.ActiveXObject)try{a=new ActiveXObject("Msxml2.XMLHTTP");}catch(b){a=new ActiveXObject("Microsoft.XMLHTTP");}return a;}function h(a,b,d,e){var h=new c();var i,j;d=d||{};e=e||{};try{i=g();}catch(k){h.done(-1,"");return h;}j=f(d);if(a==='GET'&&j){b+='?'+j;j=null;}i.open(a,b);i.setRequestHeader('Content-type','application/x-www-form-urlencoded');for(var l in e)if(e.hasOwnProperty(l))i.setRequestHeader(l,e[l]);i.onreadystatechange=function(){if(i.readyState===4)if(i.status===200)h.done(null,i.responseText);else h.done(i.status,"");};i.send(j);return h;}function i(a){return function(b,c,d){return h(a,b,c,d);};}var j={Promise:c,join:d,chain:e,ajax:h,get:i('GET'),post:i('POST'),put:i('PUT'),del:i('DELETE')};if(typeof define==='function'&&define.amd)define(function(){return j;});else a.promise=j;})(this);
}
`