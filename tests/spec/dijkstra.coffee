describe "Ivento.Dci.Examples.Dijkstra", ->
	
	class ShortestManhattanPath extends Ivento.Dci.Context

		_tentativeDistances: new Hashtable()
		_distances: new Hashtable()
		_unvisited: new Hashtable()
		_pathTo: new Hashtable()
		_initialNode: null

		constructor: (nodes, initialNode) ->
			
			convertNode = (n) ->
				node: if n? then n[0] else null
				distance: if n? then n[1] else null

			for node in nodes
				current = node[0]

				# Make a list of distance to the east and south of the node
				@_distances.put current,
					east: convertNode node[1]
					south: convertNode node[2]

				# Assign to every node a tentative distance value:
				# set it to zero for our initial node and to infinity for all other nodes.
				@_tentativeDistances.put current, if current is initialNode then 0 else Infinity

				# Create a set of the unvisited nodes called the unvisited set 
				# consisting of all the nodes except the initial node.
				@_unvisited.put current, true if current isnt initialNode
						
			# Set the initial node as current
			@_initialNode = initialNode

			# Bind roles
			@_rebind initialNode
			@bind(@_unvisited).to('unvisitedSet')
			@bind(@_tentativeDistances).to('tentativeDistances')
			@bind(@_pathTo).to('bestPath')

		# For rebinding to next node that should be calculated
		_rebind: (newNode) ->
			@bind(newNode).to('currentNode')
			@bind(newNode).to('currentIntersection')

			distance = @_distances.get(newNode)

			@bind(distance).to('edge')
			@bind(distance.east.node).to('eastNeighbor')
			@bind(distance.south.node).to('southNeighbor')

		# ===== Roles =====

		tentativeDistances:
			_contract: ['get', 'put']

			distanceTo: (node) ->
				@get node

			set: (node, distance) ->
				@put node, distance

		bestPath:
			_contract: ['get', 'put']

			fromStartTo: (destination) ->
				output = [destination]
				output.unshift @get(output[0]) while output[0] != @context._initialNode
				output

		currentIntersection:
			unvisitedNeighbors: () ->
				output = []
				output.push @context.eastNeighbor if @context.eastNeighbor?
				output.push @context.southNeighbor if @context.southNeighbor?
				output

		edge:
			_contract: ['east', 'south']

		currentNode:		
			tentativeDistance: () ->
				@context.tentativeDistances.get(@)
				
			edgeDistanceTo: (neighbor) ->
				return @context.edge.east.distance if neighbor is @context.eastNeighbor
				return @context.edge.south.distance if neighbor is @context.southNeighbor

			hasSmallestEdgeDistanceTo: (neighbor) ->
				@context.bestPath.put(neighbor, @)

		eastNeighbor:
			{}

		southNeighbor:
			{}

		unvisitedSet:
			_contract: ['remove', 'containsKey']
			
			smallestTentativeDistanceNode: () ->
				outputDistance = Infinity
				output = null
				
				@context.tentativeDistances.each (node, distance) =>
					return if not @containsKey(node)
					if output is null or distance < outputDistance
						outputDistance = distance
						output = node
		
				output

		# ===== End roles =====

		to: (destinationNode) ->

			# For the current node, consider all of its unvisited neighbors and calculate their 
			# tentative distances.
			for neighbor in @currentIntersection.unvisitedNeighbors()
				distance = @currentNode.tentativeDistance() + @currentNode.edgeDistanceTo neighbor

				# If the distance is less than the previously recorded tentative distance of 
				# the neighbor, overwrite that distance.
				if distance < @tentativeDistances.distanceTo neighbor
					@tentativeDistances.set neighbor, distance

					# Store this as the best path to the neighbor
					@currentNode.hasSmallestEdgeDistanceTo neighbor

			# Mark the current node as visited and remove it from the unvisited set.
			@unvisitedSet.remove @currentNode

			# Finish if the destination node has been marked visited.
			return @bestPath.fromStartTo destinationNode if @currentNode is destinationNode

			# Set the unvisited node marked with the smallest tentative distance as the 
			# next "current node"
			nextNode = @unvisitedSet.smallestTentativeDistanceNode()

			# Rebind the Context to the next node and calculate its distances.
			@_rebind nextNode
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
				# Node, [East, dist], [South, dist]
				[a, [b,2], [d,1]]
				[b, [c,3], [e,2]]
				[c, null,  [f,1]]
				[d, [e,1], [g,2]]
				[e, [f,1], null ]
				[f, null , [i,4]]
				[g, [h,1], null ]
				[h, [i,2], null ]
				[i, null , null ]
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

			output = new ShortestManhattanPath(nodes, a).to(i)

			expect(output.join " -> ").toEqual("a -> d -> g -> h -> i")
