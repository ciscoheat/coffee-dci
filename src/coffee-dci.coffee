# Namespace assignment
top = exports ? window
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	constructor: (@__contextProperty = 'context') ->

	bind: (rolePlayer) ->
		Context.bind @, rolePlayer, @.__contextProperty

	@isFunction: (obj) -> !!(obj && obj.constructor && obj.call && obj.apply)

	# rolePlayer: Object passed to Context in constructor
	@bind: (context, rolePlayer, contextProperty = 'context') ->
		context.__contextCache or= {}
		context.__contextCache[rolePlayer] or= {}
		# role: Role object in Context
		to: (role) ->
			cache = null
			unbind = null
			roleName = null

			applyRoleMethod = (name) ->
				-> role[name].apply rolePlayer, arguments

			assignRoleMethod = (prop, value = null) ->
				# This value is used during unbind.
				# If a property, restore value. If false, delete value.
				cache = if rolePlayer.hasOwnProperty(prop) then rolePlayer[prop] else false
				context.__contextCache[rolePlayer][prop] = cache
				rolePlayer[prop] = value ? applyRoleMethod prop

			assignRoleMethod prop for prop, field of role when role.hasOwnProperty prop

			# Assign context property to role
			assignRoleMethod contextProperty, context

			# Assign unbind method to context
			context.unbind or= ->
				for player of context.__contextCache
					for prop of context.__contextCache[player]
						cache = context.__contextCache[player][prop]
						if cache then rolePlayer[prop] = cache else delete rolePlayer[prop]
				
				# Restore original context role
				context[roleName] = context.constructor.prototype[roleName]
				delete context.unbind

			# Assign roleplayer to role in context.
			for prop, field of context
				if field is role
					roleName = prop
					context[prop] = rolePlayer
					return

			throw "Role for RolePlayer not found in Context."
