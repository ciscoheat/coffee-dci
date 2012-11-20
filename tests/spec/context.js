(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe("Ivento.Dci.Context", function() {
    var Account, ctx, entries;
    describe("Static methods", function() {
      return xit("should return the parameter names correctly from a function", function() {
        var f;
        f = function(a, bb, ccc, dddd) {
          return true;
        };
        return expect(Ivento.Dci.Context.paramNames(f)).toEqual(["a", "bb", "ccc", "dddd"]);
      });
    });
    Account = (function(_super) {

      __extends(Account, _super);

      function Account(entriesArray) {
        this.bind({
          entries: entriesArray
        }).to(this.ledgers);
      }

      Account.prototype.ledgers = {
        addEntry: function(message, amount) {
          return this.entries.push({
            message: message,
            amount: amount
          });
        },
        getBalance: function() {
          return this.entries.reduce((function(prev, curr) {
            return prev + curr.amount;
          }), 0);
        }
      };

      Account.prototype.balance = function() {
        return this.ledgers.getBalance();
      };

      Account.prototype.increaseBalance = function(amount) {
        return this.ledgers.addEntry("Depositing", amount);
      };

      Account.prototype.decreaseBalance = function(amount) {
        return this.ledgers.addEntry("Withdrawing", -amount);
      };

      return Account;

    })(Ivento.Dci.Context);
    ctx = null;
    entries = null;
    return describe("Binding behaviour", function() {
      beforeEach(function() {
        entries = [
          {
            message: "Start",
            amount: 100
          }, {
            message: "First deposit",
            amount: 1000
          }
        ];
        return ctx = new Account(entries);
      });
      it("should bind objects to roles using the bind() method", function() {
        expect(ctx.ledgers.entries).toBe(entries);
        return expect(ctx.ledgers.getBalance()).toEqual(1100);
      });
      it("should be able to use the context methods", function() {
        return expect(ctx.balance()).toEqual(ctx.ledgers.getBalance());
      });
      return it("should modify the rolePlayers correctly", function() {
        ctx.increaseBalance(200);
        expect(ctx.balance()).toEqual(1300);
        ctx.decreaseBalance(1500);
        return expect(ctx.balance()).toEqual(-200);
      });
    });
  });

}).call(this);
