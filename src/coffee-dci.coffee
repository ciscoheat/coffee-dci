# Namespace assignment
top = this
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	bind: (rolePlayer) -> Context.bind @, rolePlayer
	unbind: (name = null) -> Context.unbind @, name

	# Promise usage
	#
	# To use a custom promise framework, model an adapter
	# object based on the following predefined ones, and pass 
	# it to Context.setPromiseAdapter.

	@promiseJsAdapter:
		# factory  : Return a new promise
		factory: () -> new promise.Promise()
		# unbind   : Add unbind function f to the promise for
		#            execution when the promise is resolved.
		unbind: (p, f) -> p.then f
		# identify : For determining if the passed object is a promise.
		identify: (o) -> o.then? and o.done?

	@jQueryAdapter:
		factory: () -> jQuery.Deferred()
		unbind: (p, f) -> p.always f
		identify: (o) -> o.always? and o.done? and o.fail?

	@setPromiseAdapter: (settings) ->
		Context.promise = settings.factory
		Context.unbindPromise = settings.unbind
		Context.isPromise = settings.identify

	@promise: () -> null
	@unbindPromise: (p, f) ->
	@isPromise: (o) -> false

	# Auto-detect promise framework
	if jQuery?
		Context.setPromiseAdapter Context.jQueryAdapter
	else if promise?
		Context.setPromiseAdapter Context.promiseJsAdapter

	@_isObject: (x) -> !!(x isnt null and typeof x is 'object')
	@_isFunction: (x) -> !!(x && x.constructor && x.call && x.apply)
	@_isRoleObject: (prop, field) -> prop[0] isnt '_' and Context._isObject field
	@_isRoleMethod: (prop, method) -> prop[0] isnt '_' and prop isnt 'constructor' and Context._isFunction(method)

	@bind: (context, rolePlayer) ->
		
		isInteraction = (prop) -> 
			prop[0] isnt '_' and 
			not (prop in ['constructor', 'bind', 'unbind']) and 
			Context._isFunction(context[prop])

		bindingFor = (roleName) -> Context._bindingFor context, roleName

		doBinding = (roleName) ->

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

				# Return a function that will call Role or Object method, depending on
				# whether it's called from within the Context.
				->
					# If only Role Method is available, call it.
					return roleMethod.apply player, arguments if not objectMethod?

					caller = arguments.callee.caller.__inContext
					calledFromContext = caller is true or caller is roleName

					if calledFromContext
						return roleMethod.apply player, arguments
					else
						return objectMethod.apply player, arguments

			if player isnt null
				# Create role methods and assign them to the RolePlayer
				for prop, roleMethod of context.constructor.prototype[roleName] when Context._isRoleMethod prop, roleMethod
					player[prop] = createRoleMethod prop

				# Save previous properties
				binding.__oldContext = player[binding.__contextProperty]
				binding.__oldPromise = player.promise

				player[binding.__contextProperty] = context
				player.promise = context.promise

			# Assign RolePlayer to Role
			context[roleName] = player

		bindContext = () ->
			# Save the old promise and create a new one
			context.__oldPromise = context.promise
			context.promise = Context.promise()

			doBinding roleName for roleName of context.__isBound

		unbindContext = () ->
			Context.unbind context

			if not context.__oldPromise?
				delete context.promise
			else
				context.promise = context.__oldPromise

		createInteraction = (interactionName) ->
			# Return a method that will bind the Context, execute the Interaction
			# and unbind the Context unless a promise was returned. If a promise
			# is returned then unbinding will be done when it's resolved.
			-> 
				bindContext()
				output = null

				try
					output = context.constructor.prototype[interactionName].apply context, arguments
					output
				finally
					# Test if result was asynchronous
					if output? and Context.isPromise output
						Context.unbindPromise output, unbindContext
					else
						unbindContext()


		# Bind Interactions and Role Methods to the context prototype
		# to determine if the Role or the Object method should be called.
		proto = context.constructor.prototype
		if not proto.__isProtoBound?
			proto.__isProtoBound = true
			roleMethods = {}
			for prop, field of proto
				if isInteraction prop
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

		# Create Interactions for the context object, which are methods bound to the context.
		if not context.__isBound?
			context.__isBound = {}
			proto = context.constructor.prototype
			for prop, field of proto 
				if isInteraction prop
					context[prop] = createInteraction prop
				else if Context._isRoleObject prop, field
					# Clear Roles before they are bound so they cannot be called before a Context Method.
					context[prop] = {}

		# Return the 'to' method for completing the binding.
		to: (role, contextProperty = 'context') ->

			throw "A Role must be bound as a string literal." if not (typeof role is 'string')
			throw "Role '"+role+"' not found in Context." if not (role of context)

			# Test if RolePlayer fulfills Role Contract
			roleProto = context.constructor.prototype[role]
			if rolePlayer isnt null and roleProto._contract?
				for prop in roleProto._contract
					if prop is '()'
						if not Context._isFunction rolePlayer
							throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract: Not a function."
					else
						fields = prop.split "."
						current = rolePlayer
						while fields.length
							current = current[fields.shift()]
							if current is undefined
								throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract with property '"+prop+"'."
						
			# If rebinding roles, unbind the current.
			currentBinding = bindingFor role
			Context.unbind context, role if currentBinding?.__rolePlayer? and currentBinding.__rolePlayer isnt rolePlayer

			# Setup the binding that will be bound when executing an Interaction.
			context.__isBound[role] = Context._defaultBinding rolePlayer, contextProperty

	@unbind: (context, name = null) ->
		unbindRoleMethods = (role) ->

			binding = Context._bindingFor context, role

			return if binding.__rolePlayer is null

			rolePlayer = binding.__rolePlayer
			contextProperty = binding.__contextProperty

			restore = (obj, prop, oldValue, deleteField = undefined) ->
				if oldValue is deleteField then	delete obj[prop] else obj[prop] = oldValue

			# Unbind Role Methods
			for prop, field of binding when prop[0] isnt '_'
				restore rolePlayer, prop, field, true

			# Unbind context and promise
			restore rolePlayer, contextProperty, binding.__oldContext
			restore rolePlayer, 'promise', binding.__oldPromise

			# Note that only the Role methods are unbound,
			# the binding itself stays so it can be rebound again when needed.
			context.__isBound[role] = Context._defaultBinding rolePlayer, contextProperty
			context[role] = {}
		
		if not name?
			unbindRoleMethods role for role of context.__isBound
		else
			unbindRoleMethods name

	@_bindingFor: (context, role) ->
		context.__isBound[role]

	@_defaultBinding: (rolePlayer, contextProperty) ->
		__rolePlayer: rolePlayer
		__oldContext: null
		__oldPromise: null
		__contextProperty: contextProperty
