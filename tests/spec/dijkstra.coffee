describe "Ivento.Dci.Examples.Dijkstra", ->
	
	class ShortestPath extends Ivento.Dci.Context

		_tentativeDistances: new Hashtable()
		_distances: new Hashtable()
		_unvisited: new Hashtable()
		_smallestDistance: new Hashtable()

		constructor: (nodes, initialNode) ->
			
			# Assign to every node a tentative distance value: 
			# set it to zero for our initial node and to infinity for all other nodes.
			for node in nodes
				from = node[0]; to = node[1]; dist = node[2]

				@_tentativeDistances.put from, Infinity if not @_tentativeDistances.containsKey from
				@_tentativeDistances.put to, Infinity if not @_tentativeDistances.containsKey to
				
				@_distances.put from, new Hashtable() if not @_distances.containsKey from
				@_distances.get(from).put(to, dist)

			@_tentativeDistances.put initialNode, 0

			# Create a set of the unvisited nodes called the unvisited set 
			# consisting of all the nodes except the initial node.
			@_unvisited = @_tentativeDistances.clone()
			@_unvisited.remove initialNode

			@_rebind initialNode, @_unvisited, @_tentativeDistances

		_rebind: (currentNode, unvisitedSet, tentativeDistances) ->
			@bind(currentNode).to(@currentNode)
			@bind(unvisitedSet).to(@unvisitedSet)
			@bind(tentativeDistances).to(@tentativeDistances)

		# ===== Roles =====

		tentativeDistances:
			_contract: ['get', 'put']

			distance: (node) ->
				@get node

			setDistance: (node, distance) ->
				@put node, distance

		currentNode:
			unvisitedNeighbors: () ->
				@context._distances.get(@).keys()
		
			tentativeDistance: () ->
				@context.tentativeDistances.get(@)
				
			edgeDistance: (neighbor) ->
				@context._distances.get(@).get(neighbor)

			hasSmallestEdgeDistanceTo: (node) ->
				@context._smallestDistance.put(node, @)

		unvisitedSet:
			_contract: ['remove']
			
			smallestTentativeDistanceNode: () ->
				outputDistance = Infinity
				output = null
				
				@context.tentativeDistances.each (node, distance) =>
					return if not @containsKey(node)
					if output is null or distance < outputDistance
						dist = distance
						output = node
		
				output

		# ===== End roles =====

		to: (destinationNode) ->

			for neighbor in @currentNode.unvisitedNeighbors()
				distance = @currentNode.tentativeDistance() + @currentNode.edgeDistance neighbor

				if distance < @tentativeDistances.distance neighbor
					@tentativeDistances.setDistance neighbor, distance

			@unvisitedSet.remove @currentNode

			nextNode = @unvisitedSet.smallestTentativeDistanceNode()			
			@currentNode.hasSmallestEdgeDistanceTo nextNode

			return @_smallestDistance if nextNode is destinationNode
			
			@_rebind nextNode, @unvisitedSet, @tentativeDistances
			@to destinationNode


	# ===== Test ==============================

	describe "Using Dijkstras algorithm", ->

		it "should find the shortest path from a to i", ->

			a = new String 'a'
			b = new String 'b'
			c = new String 'c'
			d = new String 'd'
			e = new String 'e'
			f = new String 'f'
			g = new String 'g'
			h = new String 'h'
			i = new String 'i'

			nodes = [
				[a,b,2]
				[a,d,1]
				[b,c,3]
				[b,e,2]
				[c,f,1]
				[d,e,1]
				[d,g,2]
				[e,f,1]
				[f,i,4]
				[g,h,1]
				[h,i,2]
			]

			###
			a - 2 - b - 3 - c
			|       |       |
			1       2       1
			|       |       |
			d - 1 - e - 1 - f
			|               |
			2               4
			|               |
			g - 1 - h - 2 - i
			###

			path = new ShortestPath(nodes, a).to(i)

			output = [i]
			output.unshift path.get(output[0]) while output[0] != a

			expect(output.join " -> ").toEqual("a -> d -> g -> h -> i")
