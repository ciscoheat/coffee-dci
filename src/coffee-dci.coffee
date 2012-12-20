# Namespace assignment
top = exports ? window
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	constructor: (@__contextProperty) ->

	bind: (rolePlayer) ->
		Context.bind @, rolePlayer, @.__contextProperty

	@isFunction: (obj) -> !!(obj && obj.constructor && obj.call && obj.apply)
	@isObject: (obj) -> obj isnt null and typeof obj is 'object'

	# rolePlayer: Object passed to Context in constructor
	@bind: (context, rolePlayer, contextProperty = 'context') ->

		# Create rolePlayer cache id
		context.__contextCacheId or= 0
		rolePlayerCacheId = ++context.__contextCacheId

		context.__contextCache or= {}
		context.__contextCache[rolePlayerCacheId] or= {}

		contextCache = context.__contextCache

		# role: Role object in Context
		to: (role) ->
			roleMethod = null			

			# Test if RolePlayer fulfills Role Contract
			if role._contract?
				for prop in role._contract
					if not (prop of rolePlayer)
						throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract with property '"+prop+"'."

			# ===== Private methods			

			cacheFor = (prop) ->
				throw "Object for " + rolePlayer + " not found in context cache." if not contextCache[rolePlayerCacheId]?
				contextCache[rolePlayerCacheId][prop]

			setCacheFor = (prop, value) ->
				contextCache[rolePlayerCacheId][prop] = value

			isValidContextProperty = (obj, prop) -> 
				prop isnt 'constructor' and prop isnt '_contract' and obj.hasOwnProperty prop

			contextIsBound = () -> context.unbind?

			decorateContextMethods = (obj) ->
				for prop, field of obj when isValidContextProperty obj, prop
					if Context.isFunction field
						field.__contextMethod = true 
					else if Context.isObject field
						decorateContextMethods field

			applyRoleMethod = (prop) ->
				->
					objectMethod = cacheFor prop
					callingMethod = arguments.callee.caller

					# objectMethod can be 'false' so cannot test using existence
					if not objectMethod or callingMethod.__contextMethod?
						method = role[prop]
					else
						method = objectMethod

					method.apply rolePlayer, arguments
						

			assignRoleMethod = (prop, value = null) ->
				# This value is used during unbind.
				# If a property, restore value. If false, delete value.
				cache = if rolePlayer.hasOwnProperty(prop) then rolePlayer[prop] else false
				setCacheFor prop, cache
				rolePlayer[prop] = value ? applyRoleMethod prop

			# ===== End private methods

			decorateContextMethods context.constructor.prototype if not contextIsBound()

			assignRoleMethod prop for prop, field of role when isValidContextProperty role, prop

			# Assign context property to role
			assignRoleMethod contextProperty, context

			# Assign unbind method to context
			if not contextIsBound()
				context.unbind = ->
					for id of contextCache
						for prop of contextCache[id]
							cache = contextCache[id][prop]
							if cache then rolePlayer[prop] = cache else delete rolePlayer[prop]
				
					# Restore original context role
					context[roleMethod] = context.constructor.prototype[roleMethod]
					delete context.unbind

			# Assign roleplayer to role in context.
			for prop, field of context
				if field is role
					roleMethod = prop
					context[prop] = rolePlayer
					return

			throw "Role for RolePlayer not found in Context."
