(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe("Ivento.Dci.Examples.Dijkstra", function() {
    var ShortestManhattanPath;
    ShortestManhattanPath = (function(_super) {

      __extends(ShortestManhattanPath, _super);

      ShortestManhattanPath.prototype._tentativeDistances = new Hashtable();

      ShortestManhattanPath.prototype._distances = new Hashtable();

      ShortestManhattanPath.prototype._unvisited = new Hashtable();

      ShortestManhattanPath.prototype._pathTo = new Hashtable();

      ShortestManhattanPath.prototype._initialNode = null;

      function ShortestManhattanPath(nodes, initialNode) {
        var convertNode, current, node, _i, _len;
        convertNode = function(n) {
          return {
            node: n != null ? n[0] : null,
            distance: n != null ? n[1] : null
          };
        };
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          node = nodes[_i];
          current = node[0];
          this._distances.put(current, {
            east: convertNode(node[1]),
            south: convertNode(node[2])
          });
          this._tentativeDistances.put(current, current === initialNode ? 0 : Infinity);
          if (current !== initialNode) {
            this._unvisited.put(current, true);
          }
        }
        this._initialNode = initialNode;
        this._rebindNode(this._initialNode);
      }

      ShortestManhattanPath.prototype.rebind = function(newNode, unvisitedSet, tentativeDistances, bestPath, distances) {
        var distance;
        this.bind(unvisitedSet).to('unvisitedSet');
        this.bind(tentativeDistances).to('tentativeDistances');
        this.bind(bestPath).to('bestPath');
        this.bind(newNode).to('currentNode');
        this.bind(newNode).to('currentIntersection');
        distance = distances.get(newNode);
        this.bind(distance).to('edge');
        this.bind(distance.east.node).to('eastNeighbor');
        return this.bind(distance.south.node).to('southNeighbor');
      };

      ShortestManhattanPath.prototype._rebindNode = function(newNode) {
        return this.rebind(newNode, this._unvisited, this._tentativeDistances, this._pathTo, this._distances);
      };

      ShortestManhattanPath.prototype.tentativeDistances = {
        _contract: ['get', 'put'],
        distanceTo: function(node) {
          return this.get(node);
        },
        set: function(node, distance) {
          return this.put(node, distance);
        }
      };

      ShortestManhattanPath.prototype.bestPath = {
        _contract: ['get', 'put'],
        fromStartTo: function(destination) {
          var output;
          output = [destination];
          while (output[0] !== this.context._initialNode) {
            output.unshift(this.get(output[0]));
          }
          return output;
        }
      };

      ShortestManhattanPath.prototype.currentIntersection = {
        unvisitedNeighbors: function() {
          var output;
          output = [];
          if (this.context.eastNeighbor != null) {
            output.push(this.context.eastNeighbor);
          }
          if (this.context.southNeighbor != null) {
            output.push(this.context.southNeighbor);
          }
          return output;
        }
      };

      ShortestManhattanPath.prototype.edge = {
        _contract: ['east.distance', 'south.distance']
      };

      ShortestManhattanPath.prototype.currentNode = {
        tentativeDistance: function() {
          return this.context.tentativeDistances.get(this);
        },
        edgeDistanceTo: function(neighbor) {
          if (neighbor === this.context.eastNeighbor) {
            return this.context.eastNeighbor.eastNeighborDistance();
          }
          if (neighbor === this.context.southNeighbor) {
            return this.context.southNeighbor.southNeighborDistance();
          }
        },
        isBestPathTo: function(neighbor) {
          return this.context.bestPath.put(neighbor, this);
        }
      };

      ShortestManhattanPath.prototype.eastNeighbor = {
        eastNeighborDistance: function() {
          return this.context.edge.east.distance;
        }
      };

      ShortestManhattanPath.prototype.southNeighbor = {
        southNeighborDistance: function() {
          return this.context.edge.south.distance;
        }
      };

      ShortestManhattanPath.prototype.unvisitedSet = {
        _contract: ['remove', 'containsKey'],
        smallestTentativeDistanceNode: function() {
          var output, outputDistance,
            _this = this;
          outputDistance = Infinity;
          output = null;
          this.context.tentativeDistances.each(function(node, distance) {
            if (!_this.containsKey(node)) {
              return;
            }
            if (output === null || distance < outputDistance) {
              outputDistance = distance;
              return output = node;
            }
          });
          return output;
        }
      };

      ShortestManhattanPath.prototype.to = function(destinationNode) {
        var distance, neighbor, nextNode, _i, _len, _ref;
        _ref = this.currentIntersection.unvisitedNeighbors();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          neighbor = _ref[_i];
          distance = this.currentNode.tentativeDistance() + this.currentNode.edgeDistanceTo(neighbor);
          if (distance < this.tentativeDistances.distanceTo(neighbor)) {
            this.tentativeDistances.set(neighbor, distance);
            this.currentNode.isBestPathTo(neighbor);
          }
        }
        this.unvisitedSet.remove(this.currentNode);
        if (this.currentNode === destinationNode) {
          return this.bestPath.fromStartTo(destinationNode);
        }
        nextNode = this.unvisitedSet.smallestTentativeDistanceNode();
        this._rebindNode(nextNode);
        return this.to(destinationNode);
      };

      return ShortestManhattanPath;

    })(Ivento.Dci.Context);
    return describe("Using Dijkstras algorithm", function() {
      return it("should find the shortest path from a to i", function() {
        var a, b, c, d, e, f, g, h, i, nodes, output;
        a = new String('a');
        b = new String('b');
        c = new String('c');
        d = new String('d');
        e = new String('e');
        f = new String('f');
        g = new String('g');
        h = new String('h');
        i = new String('i');
        nodes = [[a, [b, 2], [d, 1]], [b, [c, 3], [e, 2]], [c, null, [f, 1]], [d, [e, 1], [g, 2]], [e, [f, 1], null], [f, null, [i, 4]], [g, [h, 1], null], [h, [i, 2], null], [i, null, null]];
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

        output = new ShortestManhattanPath(nodes, a).to(i);
        return expect(output.join(" -> ")).toEqual("a -> d -> g -> h -> i");
      });
    });
  });

}).call(this);
