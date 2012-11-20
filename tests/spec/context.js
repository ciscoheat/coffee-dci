(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe("Ivento.Dci.Context", function() {
    var Account, SimplerAccount, ctx, entries;
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
    SimplerAccount = (function() {

      function SimplerAccount(entriesArray) {
        Ivento.Dci.Context.bind(this, {
          entries: entriesArray
        }).to(this.ledgers);
      }

      SimplerAccount.prototype.ledgers = {
        getBalance: function() {
          return this.entries.reduce((function(prev, curr) {
            return prev + curr.amount;
          }), 0);
        }
      };

      SimplerAccount.prototype.balance = function() {
        return this.ledgers.getBalance();
      };

      return SimplerAccount;

    })();
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
      it("should modify the rolePlayers correctly", function() {
        ctx.increaseBalance(200);
        expect(ctx.balance()).toEqual(1300);
        ctx.decreaseBalance(1500);
        return expect(ctx.balance()).toEqual(-200);
      });
      return it("should bind to objects not using inheritance with the static method.", function() {
        var simple;
        simple = new SimplerAccount(entries);
        return expect(simple.balance()).toEqual(1100);
      });
    });
  });

}).call(this);
