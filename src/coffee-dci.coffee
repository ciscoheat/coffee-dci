# Namespace assignment
top = exports ? window
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	bind: (rolePlayer) -> Context.bind @, rolePlayer

	@bind: (context, rolePlayer) ->

		isFunction = (x) -> !!(x && x.constructor && x.call && x.apply)
		isObject = (x) -> x isnt null and typeof x is 'object'

		isRoleObject = (field) -> isObject field
		isContextMethod = (prop) -> prop[0] isnt '_' and prop isnt 'constructor' and isFunction(context[prop])
		isRoleMethod = (prop, method) -> prop[0] isnt '_' and prop isnt 'constructor' and isFunction(method)

		createContextMethod = (prop) ->
			->
				prevContext = Context.__current
				Context.__current = context
				try
					context.constructor.prototype[prop].apply context, arguments
				finally
					Context.__current = prevContext

		# Bind context methods to current context
		if not context.__methodBound?
			context.__methodBound = true
			for prop, field of context.constructor.prototype
				if isContextMethod prop
					context.constructor.prototype[prop].__contextMethod = true
					context[prop] = createContextMethod prop
				else if isRoleObject field
					for roleName, roleMethod of field when isRoleMethod roleName, roleMethod
						context.constructor.prototype[prop][roleName].__contextMethod = prop

		to: (role, contextProperty = 'context') ->			

			roleProp = null

			# Test if Role exists in Context
			for prop, field of context
				if field is role 
					roleProp = prop
					break

			throw "Role for RolePlayer not found in Context." if not roleProp

			# Test if RolePlayer fulfills Role Contract
			if role._contract?
				for prop in role._contract
					throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract with property '"+prop+"'." if not (prop of rolePlayer)						

			roleKeys = () ->
				keys = (prop for prop, field of context.constructor.prototype[roleProp] when isRoleMethod prop, field)
				keys = keys.concat role._contract if role._contract?
				keys

			createRoleMethod = (prop, roleMethod, objectMethod) ->
				->
					oldContext = rolePlayer[contextProperty]
					rolePlayer[contextProperty] = Context.__current

					caller = arguments.callee.caller.__contextMethod
					calledFromContext = caller is true or caller is roleProp

					try
						# If only Role Method is available, call it.
						if roleMethod? and not objectMethod?
							# Does not work with Iced Coffeescript:
							#throw "Access to Role '" + roleProp + "." + prop + "' from outside Context." if not caller
							return context.constructor.prototype[roleProp][prop].apply rolePlayer, arguments

						# If only Object Method is available, call it.
						if objectMethod? and not roleMethod?
							return objectMethod.apply rolePlayer, arguments

						# If both Role and Object Method is available, determine if method was called
						# from a Context, and call Role Method if so, Object Method otherwise.
						if roleMethod and objectMethod
							if calledFromContext
								return context.constructor.prototype[roleProp][prop].apply rolePlayer, arguments
							else
								return objectMethod.apply rolePlayer, arguments

						throw "No Role Method or Object Method '" + prop + "' found."

					finally
						if oldContext?
							rolePlayer[contextProperty] = oldContext
						else
							delete rolePlayer[contextProperty]

			# Bind role methods
			rolePlayerType = typeof rolePlayer
			context[roleProp] = if rolePlayerType in ['boolean', 'number', 'string'] then rolePlayer else {}

			# Need to duplicate the role object to preserve the context closure.
			for prop in roleKeys()
				roleMethod = context.constructor.prototype[roleProp][prop]
				objectMethod = rolePlayer[prop]

				context[roleProp][prop] = createRoleMethod prop, roleMethod, objectMethod
				
				# If name collision, set rolePlayer property as well.
				rolePlayer[prop] = context[roleProp][prop] if roleMethod and objectMethod
			