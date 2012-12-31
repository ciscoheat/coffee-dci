(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe("Ivento.Dci.Examples.Dijkstra", function() {
    var ShortestPath;
    ShortestPath = (function(_super) {

      __extends(ShortestPath, _super);

      ShortestPath.prototype._tentativeDistances = new Hashtable();

      ShortestPath.prototype._distances = new Hashtable();

      ShortestPath.prototype._unvisited = new Hashtable();

      ShortestPath.prototype._smallestDistance = new Hashtable();

      function ShortestPath(nodes, initialNode) {
        var dist, from, node, to, _i, _len;
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          node = nodes[_i];
          from = node[0];
          to = node[1];
          dist = node[2];
          if (!this._tentativeDistances.containsKey(from)) {
            this._tentativeDistances.put(from, Infinity);
          }
          if (!this._tentativeDistances.containsKey(to)) {
            this._tentativeDistances.put(to, Infinity);
          }
          if (!this._distances.containsKey(from)) {
            this._distances.put(from, new Hashtable());
          }
          this._distances.get(from).put(to, dist);
        }
        this._tentativeDistances.put(initialNode, 0);
        this._unvisited = this._tentativeDistances.clone();
        this._unvisited.remove(initialNode);
        this._rebind(initialNode, this._unvisited, this._tentativeDistances);
      }

      ShortestPath.prototype._rebind = function(currentNode, unvisitedSet, tentativeDistances) {
        this.bind(currentNode).to(this.currentNode);
        this.bind(unvisitedSet).to(this.unvisitedSet);
        return this.bind(tentativeDistances).to(this.tentativeDistances);
      };

      ShortestPath.prototype.tentativeDistances = {
        _contract: ['get', 'put'],
        distance: function(node) {
          return this.get(node);
        },
        setDistance: function(node, distance) {
          return this.put(node, distance);
        }
      };

      ShortestPath.prototype.currentNode = {
        unvisitedNeighbors: function() {
          return this.context._distances.get(this).keys();
        },
        tentativeDistance: function() {
          return this.context.tentativeDistances.get(this);
        },
        edgeDistance: function(neighbor) {
          return this.context._distances.get(this).get(neighbor);
        },
        hasSmallestEdgeDistanceTo: function(node) {
          return this.context._smallestDistance.put(node, this);
        }
      };

      ShortestPath.prototype.unvisitedSet = {
        _contract: ['remove'],
        smallestTentativeDistanceNode: function() {
          var output, outputDistance,
            _this = this;
          outputDistance = Infinity;
          output = null;
          this.context.tentativeDistances.each(function(node, distance) {
            var dist;
            if (!_this.containsKey(node)) {
              return;
            }
            if (output === null || distance < outputDistance) {
              dist = distance;
              return output = node;
            }
          });
          return output;
        }
      };

      ShortestPath.prototype.to = function(destinationNode) {
        var distance, neighbor, nextNode, _i, _len, _ref;
        _ref = this.currentNode.unvisitedNeighbors();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          neighbor = _ref[_i];
          distance = this.currentNode.tentativeDistance() + this.currentNode.edgeDistance(neighbor);
          if (distance < this.tentativeDistances.distance(neighbor)) {
            this.tentativeDistances.setDistance(neighbor, distance);
          }
        }
        this.unvisitedSet.remove(this.currentNode);
        nextNode = this.unvisitedSet.smallestTentativeDistanceNode();
        this.currentNode.hasSmallestEdgeDistanceTo(nextNode);
        if (nextNode === destinationNode) {
          return this._smallestDistance;
        }
        this._rebind(nextNode, this.unvisitedSet, this.tentativeDistances);
        return this.to(destinationNode);
      };

      return ShortestPath;

    })(Ivento.Dci.Context);
    return describe("Using Dijkstras algorithm", function() {
      return it("should find the shortest path from a to i", function() {
        var a, b, c, d, e, f, g, h, i, nodes, output, path;
        a = new String('a');
        b = new String('b');
        c = new String('c');
        d = new String('d');
        e = new String('e');
        f = new String('f');
        g = new String('g');
        h = new String('h');
        i = new String('i');
        nodes = [[a, b, 2], [a, d, 1], [b, c, 3], [b, e, 2], [c, f, 1], [d, e, 1], [d, g, 2], [e, f, 1], [f, i, 4], [g, h, 1], [h, i, 2]];
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

        path = new ShortestPath(nodes, a).to(i);
        output = [i];
        while (output[0] !== a) {
          output.unshift(path.get(output[0]));
        }
        return expect(output.join(" -> ")).toEqual("a -> d -> g -> h -> i");
      });
    });
  });

}).call(this);
