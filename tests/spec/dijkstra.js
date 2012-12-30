(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe("Ivento.Dci.Examples.Dijkstra", function() {
    var Graph, Node, SubGraph;
    SubGraph = (function(_super) {

      __extends(SubGraph, _super);

      function SubGraph(node, graph) {
        this.bind(node).to(this.node);
        this.bind(graph).to(this.graph);
        graph.distances.put(node, 0);
      }

      SubGraph.prototype.graph = {
        _contract: ['nodes', 'distances', 'previous'],
        distanceBetween: function(node, other) {
          return this.nodes.get(node).get(other);
        },
        removeNode: function() {
          return this.nodes.remove(this.context.node);
        },
        updateDistance: function(node, distance) {
          return this.distances.put(node, distance);
        }
      };

      SubGraph.prototype.node = {
        neighbors: function() {
          return this.context.graph.nodes.get(this);
        },
        distance: function() {
          return this.context.graph.distances.get(this);
        },
        isPreviousOf: function(n) {
          return this.context.graph.previous.put(n, this);
        },
        distanceTo: function(other) {
          return this.context.graph.distanceBetween(this, other);
        },
        neighborWithShortestPath: function() {
          var current, distance, node, output, _i, _len, _ref;
          current = Infinity;
          output = null;
          _ref = this.context.graph.nodes.keys();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            node = _ref[_i];
            distance = this.context.graph.distances.get(node);
            if (distance < current) {
              output = node;
              current = distance;
            }
          }
          return output;
        }
      };

      SubGraph.prototype.findShortestPath = function() {
        var alt, neighbor, neighbors, next, _i, _len, _ref;
        neighbors = this.node.neighbors();
        if (neighbors.isEmpty()) {
          return this.graph.previous;
        }
        _ref = neighbors.keys();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          neighbor = _ref[_i];
          alt = this.node.distance() + this.node.distanceTo(neighbor);
          if (alt < this.graph.distances.get(neighbor)) {
            this.graph.updateDistance(neighbor, alt);
            this.node.isPreviousOf(neighbor);
          }
        }
        this.graph.removeNode();
        next = this.node.neighborWithShortestPath();
        new SubGraph(next, this.graph).findShortestPath();
        return this.graph.previous;
      };

      return SubGraph;

    })(Ivento.Dci.Context);
    Node = (function() {

      function Node(name) {
        this.toString = function() {
          return name;
        };
      }

      return Node;

    })();
    Graph = (function() {

      Graph.prototype.distances = new Hashtable();

      Graph.prototype.previous = new Hashtable();

      Graph.prototype.nodes = new Hashtable();

      function Graph(nodes) {
        var dist, from, node, to, _i, _len;
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          node = nodes[_i];
          from = node[0];
          to = node[1];
          dist = node[2];
          if (!this.nodes.containsKey(from)) {
            this.nodes.put(from, new Hashtable());
          }
          if (!this.distances.containsKey(from)) {
            this.distances.put(from, Infinity);
          }
          if (!this.nodes.containsKey(to)) {
            this.nodes.put(to, new Hashtable());
          }
          if (!this.distances.containsKey(to)) {
            this.distances.put(to, Infinity);
          }
          this.nodes.get(from).put(to, dist);
        }
      }

      return Graph;

    })();
    return describe("Using Dijkstras algorithm", function() {
      return it("should find the shortest path from a to i", function() {
        var a, b, c, d, e, f, g, graph, h, i, output, path, paths;
        a = new Node('a');
        b = new Node('b');
        c = new Node('c');
        d = new Node('d');
        e = new Node('e');
        f = new Node('f');
        g = new Node('g');
        h = new Node('h');
        i = new Node('i');
        paths = [[a, b, 2], [a, d, 1], [b, c, 3], [b, e, 2], [c, f, 1], [d, e, 1], [d, g, 2], [e, f, 1], [f, i, 4], [g, h, 1], [h, i, 2]];
        /*
        			a - 2 - b - 3 - c
        			|       |       |
        			1       2       1
        			|       |       |
        			d - 1 - e - 1 - f
        			|               |
        			2               4
        			|               |
        			g - 1 - h - 2 - i
        */

        graph = new Graph(paths);
        path = new SubGraph(a, graph).findShortestPath();
        output = [i];
        while (output[0] !== a) {
          output.unshift(path.get(output[0]));
        }
        return expect(output.join(" -> ")).toEqual("a -> d -> g -> h -> i");
      });
    });
  });

}).call(this);
