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

			roleProperty = null			

			for prop, field of context
				if field is role
					roleProperty = prop
					context[prop] = rolePlayer
					break

			throw "Role for RolePlayer not found in Context." if not roleProperty

			# ===== Private methods			

			cacheFor = (prop) ->
				throw "Object for " + rolePlayer + " not found in context cache." if not contextCache[rolePlayerCacheId]?
				contextCache[rolePlayerCacheId][prop]

			setCacheFor = (prop, value) ->
				contextCache[rolePlayerCacheId][prop] = value

			isValidContextProperty = (obj, prop) -> 
				prop isnt 'constructor' and prop isnt '_contract' and obj.hasOwnProperty prop

			contextIsBound = () -> context.unbind?

			contextRole = () ->
				context.constructor.prototype[roleProperty]

			decorateContextMethods = (obj, roleMethods) ->
				for prop, field of obj when isValidContextProperty obj, prop
					if not field.__contextMethod and Context.isFunction field
						field.__contextMethod = if roleMethods then roleProperty else true
					else if prop is roleProperty
						decorateContextMethods field, true

			applyRoleMethod = (prop) ->
				->
					objectMethod = cacheFor prop
					contextCaller = arguments.callee.caller.__contextMethod

					# objectMethod can be false so cannot test using existence.
					# if contextCall is true, the role method is called from a context method (interaction)
					if not objectMethod or contextCaller is true or contextCaller is roleProperty
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

			# Test if RolePlayer fulfills Role Contract
			if role._contract?
				for prop in role._contract
					if not (prop of rolePlayer)
						throw "RolePlayer "+rolePlayer+" didn't fulfill Role Contract with property '"+prop+"'."

			decorateContextMethods context.constructor.prototype, false

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
					context[roleProperty] = context.constructor.prototype[roleProperty]
					delete context.unbind
						
