describe "Ivento.Dci.Examples.Dijkstra", ->

	class SubGraph extends Ivento.Dci.Context
		constructor: (node, graph) ->
			@bind(node).to(@node)
			@bind(graph).to(@graph)

			# Cannot call graph.updateDistance directly from constructor, 
			# so this little hack is needed.
			graph.distances.put(node, 0)

		# ===== Roles =====

		graph:
			_contract: ['nodes', 'distances', 'previous']

			distanceBetween: (node, other) ->
				@nodes.get(node).get(other)

			removeNode: () ->
				@nodes.remove @context.node

			updateDistance: (node, distance) ->
				@distances.put(node, distance)

		node:
			neighbors: () ->
				@context.graph.nodes.get(@)

			distance: () ->
				@context.graph.distances.get(@)

			isPreviousOf: (n) ->
				@context.graph.previous.put(n, @)

			distanceTo: (other) ->
				@context.graph.distanceBetween @, other

			neighborWithShortestPath: () ->
				current = Infinity
				output = null
				for node in @context.graph.nodes.keys() 
					distance = @context.graph.distances.get(node)
					if distance < current
						output = node
						current = distance
				output
		
		# ===== End roles =====

		findShortestPath: () ->
			neighbors = @node.neighbors()
			return @graph.previous if neighbors.isEmpty()

			for neighbor in neighbors.keys()
				alt = @node.distance() + @node.distanceTo neighbor
				if alt < @graph.distances.get neighbor
					@graph.updateDistance neighbor, alt
					@node.isPreviousOf neighbor

			@graph.removeNode()
			next = @node.neighborWithShortestPath()
			new SubGraph(next, @graph).findShortestPath()
			
			@graph.previous

	class Node
		constructor: (name) ->
			@toString = () -> name

	class Graph		
		# Node -> double
		distances: new Hashtable()

		# Node -> Node
		previous: new Hashtable()

		# Node -> (Node -> double)
		nodes: new Hashtable()

		constructor: (nodes) ->
			for node in nodes
				from = node[0]
				to = node[1]
				dist = node[2]

				@nodes.put from, new Hashtable() if not @nodes.containsKey from
				@distances.put from, Infinity if not @distances.containsKey from

				@nodes.put to, new Hashtable() if not @nodes.containsKey to
				@distances.put to, Infinity if not @distances.containsKey to

				@nodes.get(from).put(to, dist)

	# ===== Test ==============================

	describe "Using Dijkstras algorithm", ->

		it "should find the shortest path from a to i", ->

			a = new Node 'a'
			b = new Node 'b'
			c = new Node 'c'
			d = new Node 'd'
			e = new Node 'e'
			f = new Node 'f'
			g = new Node 'g'
			h = new Node 'h'
			i = new Node 'i'

			paths = [
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

			graph = new Graph paths
			path = new SubGraph(a, graph).findShortestPath()

			output = [i]
			output.unshift path.get(output[0]) while output[0] != a

			expect(output.join " -> ").toEqual("a -> d -> g -> h -> i")
