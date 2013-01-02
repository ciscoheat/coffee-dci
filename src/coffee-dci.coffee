# Namespace assignment
top = this
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	bind: (rolePlayer) -> Context.bind @, rolePlayer
	unbind: (name = null) -> Context.unbind @, name

	@setPromiseAdapter: (settings) ->
		Context.promise = settings.factory
		Context.unbindPromise = settings.unbind
		Context.isPromise = settings.identify

	@promise: () -> new top.promise.Promise()
	@unbindPromise: (p, f) -> p.then f
	@isPromise: (p) -> p.then? and p.done?

	@_isObject: (x) -> !!(x isnt null and typeof x is 'object')
	@_isFunction: (x) -> !!(x && x.constructor && x.call && x.apply)
	@_isRoleObject: (prop, field) -> prop[0] isnt '_' and @_isObject field
	@_isRoleMethod: (prop, method) -> prop[0] isnt '_' and prop isnt 'constructor' and @._isFunction(method)

	@bind: (context, rolePlayer) ->
		
		isContextMethod = (prop) -> 
			prop[0] isnt '_' and 
			not (prop in ['constructor', 'bind', 'unbind']) and 
			Context._isFunction(context[prop])

		bindingFor = (roleName) -> Context._bindingFor context, roleName

		doBinding = (contextMethodName, roleName) ->

			binding = bindingFor roleName
			player = binding.__rolePlayer

			createRoleMethod = (prop) ->

				objectMethod = player[prop]
				roleMethod = context.constructor.prototype[roleName][prop]

				# If only Object Method is available, nothing changes
				return objectMethod if objectMethod? and not roleMethod?

				throw "No Role method or Object method '" + prop + "' found." if not objectMethod? and not roleMethod?

				# Set binding, if true then delete field on unbind, else restore old field.
				if not objectMethod?
					binding[prop] = true
				else
					binding[prop] = objectMethod				

				->
					# If only Role Method is available, call it.						
					return roleMethod.apply player, arguments if not objectMethod?

					# If both Role and Object Method is available, determine if method was called
					# from a Context, and call Role Method if so, if not call Object Method.
					caller = arguments.callee.caller.__inContext
					calledFromContext = caller is true or caller is roleName

					if calledFromContext
						return roleMethod.apply player, arguments
					else
						return objectMethod.apply player, arguments # rolePlayer or this?

			# Test if rolePlayer can be null, if not do property assignment.
			if player isnt null

				# Create role methods and assign them to the RolePlayer
				for prop, roleMethod of context.constructor.prototype[roleName] when Context._isRoleMethod prop, roleMethod
					player[prop] = createRoleMethod prop

				# Save previous properties
				binding.__oldContext = player[binding.__contextProperty]
				binding.__oldPromise = player.promise

				player[binding.__contextProperty] = context
				player.promise = context[contextMethodName].__promise

			# Assign RolePlayer to Role
			context[roleName] = player

		doBindings = (contextMethodName) ->
			for roleName of context.__isBound
				doBinding contextMethodName, roleName

		unbindContext = (context, oldPromise) ->
			Context.unbind context

			if oldPromise is undefined
				delete context.promise
			else
				context.promise = oldPromise

		createContextMethod = (contextMethodName) ->
			-> 
				oldPromise = context.promise

				context[contextMethodName].__promise or= Context.promise()
				context.promise = context[contextMethodName].__promise

				doBindings contextMethodName

				output = null
				try
					output = context.constructor.prototype[contextMethodName].apply context, arguments
					output
				finally
					unbind = -> unbindContext context, oldPromise

					# Test if result was asynchronous
					if output? and Context.isPromise output
						Context.unbindPromise(output, unbind)
					else
						unbind()


		# Bind Context and Role methods to current context,
		# to determine if the Context or the Object method should be called.
		proto = context.constructor.prototype

		if not proto.__isProtoBound?
			proto.__isProtoBound = true
			roleMethods = {}
			for prop, field of proto
				if isContextMethod prop
					# Context methods should always use the Role Method (true)
					proto[prop].__inContext = true
				else if Context._isRoleObject prop, field
					roleName = prop
					for roleMethodName, roleMethod of field when Context._isRoleMethod roleMethodName, roleMethod
						# Role methods should be used in the same Role (Role name)
						proto[prop][roleMethodName].__inContext = roleName

						# Test for Role Method conflicts
						if roleMethods[roleMethodName]?
							throw "Method name conflict in Roles '" + roleMethods[roleMethodName] + "' and '" + 
							roleName + "." + roleMethodName + "'. Please prepend the Role names to the methods to avoid conflict."
						else
							roleMethods[roleMethodName] = roleName + "." + roleMethodName

		if not context.__isBound?
			context.__isBound = {}
			proto = context.constructor.prototype
			for prop, field of proto 
				if isContextMethod prop
					context[prop] = createContextMethod prop
				else if Context._isRoleObject prop, field
					# Clear Roles before they are bound so they cannot be called before a Context Method.
					context[prop] = {}

		# Return the 'to' method to complete the binding.
		to: (role, contextProperty = 'context') ->

			throw "A Role must be bound as a string literal." if not (typeof role is 'string')
			throw "Role '"+role+"' not found in Context." if not (role of context)

			# Test if RolePlayer fulfills Role Contract
			roleProto = context.constructor.prototype[role]
			if rolePlayer isnt null and roleProto._contract?
				for prop in roleProto._contract
					fields = prop.split "."
					current = rolePlayer
					while fields.length
						current = current[fields.shift()]
						if current is undefined
							throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract with property '"+prop+"'." 
						
			# If rebinding roles, unbind the current.
			prevBinding = bindingFor role
			Context.unbind context, role if prevBinding? and prevBinding.__rolePlayer? and prevBinding.__rolePlayer isnt rolePlayer

			# Setup the binding, for usage when executing a Context Method
			context.__isBound[role] = Context._defaultBinding rolePlayer, contextProperty

	@unbind: (context, name = null) ->
		unbindMethods = (role) ->

			binding = Context._bindingFor context, role
			rolePlayer = binding.__rolePlayer
			contextProperty = binding.__contextProperty

			return if rolePlayer is null

			# Unbind Role Methods
			for prop, field of binding when prop[0] isnt '_'
				if field is true
					delete rolePlayer[prop]
				else
					rolePlayer[prop] = field

			# Unbind context and promise
			oldContext = binding.__oldContext
			if oldContext is undefined
				delete rolePlayer[contextProperty]
			else
				rolePlayer[contextProperty] = oldContext

			oldPromise = binding.__oldPromise
			if oldPromise is undefined
				delete rolePlayer.promise
			else
				rolePlayer.promise = oldPromise

			context.__isBound[role] = Context._defaultBinding rolePlayer, contextProperty
			context[role] = {}
		
		if not name?
			unbindMethods role for role of context.__isBound
		else
			unbindMethods name

	@_bindingFor: (context, role) ->
		context.__isBound[role]

	@_defaultBinding: (rolePlayer, contextProperty) ->
		__rolePlayer: rolePlayer
		__oldContext: null
		__oldPromise: null
		__contextProperty: contextProperty

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