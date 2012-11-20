(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe("Ivento.Dci.Context", function() {
    var Account, SimplerAccount, ctx, entries;
    Account = (function(_super) {

      __extends(Account, _super);

      function Account(entriesArray) {
        if (entriesArray == null) {
          entriesArray = [];
        }
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
    describe("Binding behaviour", function() {
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
    describe("MoneyTransfer Context", function() {
      var MoneyTransfer;
      MoneyTransfer = (function(_super) {

        __extends(MoneyTransfer, _super);

        function MoneyTransfer(source, destination, amount) {
          this.bind(source).to(this.source);
          this.bind(destination).to(this.destination);
          this.bind(amount).to(this.amount);
        }

        MoneyTransfer.prototype.source = {
          withdraw: function(amount) {
            return this.decreaseBalance(amount);
          },
          transfer: function(amount) {
            this.context.destination.deposit(amount);
            return this.context.source.withdraw(amount);
          }
        };

        MoneyTransfer.prototype.destination = {
          deposit: function(amount) {
            return this.increaseBalance(amount);
          }
        };

        MoneyTransfer.prototype.amount = {};

        MoneyTransfer.prototype.transfer = function() {
          return this.source.transfer(this.amount);
        };

        return MoneyTransfer;

      })(Ivento.Dci.Context);
      return it("should transfer money using Accounts", function() {
        var amount, context, dest, src;
        src = new Account(entries);
        dest = new Account;
        amount = 200;
        expect(src.balance()).toEqual(1100);
        expect(dest.balance()).toEqual(0);
        context = new MoneyTransfer(src, dest, amount);
        context.transfer();
        expect(src.balance()).toEqual(900);
        return expect(dest.balance()).toEqual(200);
      });
    });
    return describe("Unbinding behavior", function() {
      var SpiderMan, SuperMan, man;
      man = null;
      beforeEach(function() {
        return man = {
          name: "Clark Kent",
          useXRay: function() {
            return "Prevented by glasses.";
          }
        };
      });
      SpiderMan = (function(_super) {

        __extends(SpiderMan, _super);

        function SpiderMan(man) {}

        SpiderMan.prototype.spiderman = {
          useWeb: function() {
            return "fzzzt!";
          }
        };

        return SpiderMan;

      })(Ivento.Dci.Context);
      SuperMan = (function(_super) {

        __extends(SuperMan, _super);

        function SuperMan(man) {
          this.bind(man).to(this.superman);
        }

        SuperMan.prototype.superman = {
          useXRay: function() {
            return "wzzzt!";
          },
          fly: function() {
            return "wheee!";
          }
        };

        SuperMan.prototype.execute = function() {
          return this.superman.fly();
        };

        return SuperMan;

      })(Ivento.Dci.Context);
      it("should have an unbind method added after the first bind", function() {
        var spider, superMan;
        spider = new SpiderMan(man);
        expect(spider.unbind).toBeUndefined();
        superMan = new SuperMan(man);
        return expect(superMan.unbind).toBeDefined();
      });
      return it("unbind() should remove the role methods from the rolePlayer", function() {
        var superMan;
        superMan = new SuperMan(man);
        expect(man.useXRay()).toEqual("wzzzt!");
        expect(man.fly()).toEqual("wheee!");
        superMan.unbind();
        expect(man.fly).toBeUndefined();
        expect(man.useXRay()).toEqual("Prevented by glasses.");
        return expect(superMan.unbind).toBeUndefined();
      });
    });
  });

}).call(this);
