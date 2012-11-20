# Namespace assignment
top = exports ? window
top.Ivento or= {}
top.Ivento.Dci or= {}

# Context class
top.Ivento.Dci.Context = class Context

	bind: (rolePlayer) ->
		Context.bind @, rolePlayer

	# rolePlayer: Object passed to Context in constructor
	@bind: (context, rolePlayer) ->
		cacheName = "__methodCache"
		# role: Role object in Context
		to: (role) ->
			cache = null
			unbind = null
			roleName = null

			applyRoleMethod = (name) ->
				-> role[name].apply rolePlayer, arguments

			for prop, field of role
				if role.hasOwnProperty(prop)
					if rolePlayer.hasOwnProperty(prop)
						rolePlayer[cacheName] or= {}
						rolePlayer[cacheName][prop] = rolePlayer[prop]
					rolePlayer[prop] = applyRoleMethod prop

			unbind = rolePlayer.unbind
			cache.unbind = unbind if unbind
			rolePlayer.unbind = ->
				prop = undefined
				cache = rolePlayer[cacheName]
				for prop, field of role
					delete rolePlayer[prop] if role.hasOwnProperty(prop) and rolePlayer.hasOwnProperty(prop)
				delete rolePlayer.unbind
		
				if cache
					for prop, field of cache
						rolePlayer[prop] = cache[prop]

				context[roleName] = context.prototype[roleName]

			for prop, field of context
				if field is role
					roleName = prop
					context[prop] = rolePlayer
					return

			throw "Role for RolePlayer not found in Context."
