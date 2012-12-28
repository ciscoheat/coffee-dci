(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  describe("Ivento.Dci.Context", function() {
    var Account, SimplerAccount, entries;
    Account = (function(_super) {

      __extends(Account, _super);

      function Account(entries) {
        if (entries == null) {
          entries = [];
        }
        this.bind(entries).to(this.ledgers);
        this.bind(entries).to(this.balancer);
      }

      Account.prototype.balancer = {
        _contract: ['reduce'],
        getBalance: function() {
          return this.reduce((function(prev, curr) {
            return prev + curr.amount;
          }), 0);
        }
      };

      Account.prototype.ledgers = {
        _contract: ['push'],
        addEntry: function(message, amount) {
          return this.push({
            message: message,
            amount: amount
          });
        },
        getBalance: function() {
          return this.context.balancer.getBalance();
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
        _contract: ['entries'],
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
      return window.entries = entries;
    });
    describe("Binding behaviour", function() {
      var ctx;
      ctx = null;
      beforeEach(function() {
        return ctx = new Account(entries);
      });
      it("should bind objects to roles using the bind() method", function() {
        return expect(ctx.ledgers).toBeDefined();
      });
      it("should be able to use the context methods", function() {
        return expect(ctx.balance()).toEqual(1100);
      });
      it("should modify the rolePlayers correctly", function() {
        expect(entries.length).toBe(2);
        ctx.increaseBalance(200);
        expect(entries.length).toBe(3);
        expect(entries[2]).toEqual({
          message: "Depositing",
          amount: 200
        });
        expect(ctx.balance()).toEqual(1300);
        ctx.decreaseBalance(1500);
        expect(ctx.balance()).toEqual(-200);
        return expect(entries[3]).toEqual({
          message: "Withdrawing",
          amount: -1500
        });
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
          _contract: ['decreaseBalance'],
          withdraw: function(amount) {
            return this.decreaseBalance(amount);
          },
          transfer: function(amount) {
            this.context.destination.deposit(amount);
            return this.context.source.withdraw(amount);
          }
        };

        MoneyTransfer.prototype.destination = {
          _contract: ['increaseBalance'],
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
        var context, dest, src;
        src = new Account(entries);
        dest = new Account;
        expect(src.balance()).toEqual(1100);
        expect(dest.balance()).toEqual(0);
        context = new MoneyTransfer(src, dest, 200);
        context.transfer();
        expect(src.balance()).toEqual(900);
        return expect(dest.balance()).toEqual(200);
      });
    });
    describe("Role Contracts", function() {
      var Restaurant;
      Restaurant = (function(_super) {

        __extends(Restaurant, _super);

        function Restaurant(guests, waiter) {
          this.bind(guests).to(this.guests);
          this.bind(waiter).to(this.waiter);
        }

        Restaurant.prototype.waiter = {
          _contract: ['name'],
          greetGuests: function() {
            return "Welcome, my name is " + this.name + ", I'll be your waiter tonight.";
          }
        };

        Restaurant.prototype.guests = {
          _contract: ['add', 'remove']
        };

        Restaurant.prototype.greet = function() {
          return this.waiter.greetGuests();
        };

        Restaurant.prototype.addGuest = function(name) {
          return this.guests.add(name);
        };

        return Restaurant;

      })(Ivento.Dci.Context);
      it("should ensure that the RolePlayer has all contract properties in the _contract array", function() {
        var context, guests, person;
        person = {
          name: "Henry"
        };
        guests = [];
        guests.add = guests.push;
        guests.remove = function(g) {
          return delete this[g];
        };
        context = new Restaurant(guests, person);
        expect(context.greet()).toEqual("Welcome, my name is Henry, I'll be your waiter tonight.");
        return expect(context.addGuest("Someone")).toEqual(1);
      });
      return it("should throw an Exception if the RolePlayer doesn't have all the properties in the _contract array", function() {
        var anonymous, guests;
        anonymous = {};
        guests = [];
        guests.add = guests.push;
        guests.remove = function(g) {
          return delete this[g];
        };
        return expect(function() {
          return new Restaurant(guests, anonymous);
        }).toThrow("RolePlayer [object Object] didn't fulfill Role Contract with property 'name'.");
      });
    });
    describe("Role method accessing behavior for name conflicts", function() {
      var DbAccount, Game, LogAccount, MultiRoles;
      LogAccount = (function(_super) {

        __extends(LogAccount, _super);

        function LogAccount(account) {
          this.bind(account).to(this.account);
        }

        LogAccount.prototype.account = {
          _contract: ['save', 'write'],
          transfer: function() {
            this.save();
            return this.write();
          },
          write: function() {
            return this.logWritten = true;
          }
        };

        LogAccount.prototype.transfer = function() {
          return this.account.transfer();
        };

        return LogAccount;

      })(Ivento.Dci.Context);
      DbAccount = (function() {

        function DbAccount(amount) {
          this.amount = amount;
          this.write = __bind(this.write, this);

          this.validate = __bind(this.validate, this);

          this.save = __bind(this.save, this);

        }

        DbAccount.prototype.save = function() {
          if (this.validate()) {
            return this.write();
          }
        };

        DbAccount.prototype.validate = function() {
          return this.amount > 0;
        };

        DbAccount.prototype.write = function() {
          return this.dbWritten = true;
        };

        return DbAccount;

      })();
      MultiRoles = (function(_super) {

        __extends(MultiRoles, _super);

        function MultiRoles(object) {
          if (object == null) {
            object = {};
          }
          this.bind(object).to(this.source);
          this.bind(object).to(this.target);
        }

        MultiRoles.prototype.source = {
          foo: function() {
            return "source";
          }
        };

        MultiRoles.prototype.target = {
          foo: function() {
            return "target";
          }
        };

        MultiRoles.prototype.doIt = function() {
          return this.source.foo() + this.target.foo();
        };

        return MultiRoles;

      })(Ivento.Dci.Context);
      Game = (function(_super) {

        __extends(Game, _super);

        function Game(player) {
          this.bind(player).to(this.player);
          this.bind(player).to(this.judge);
        }

        Game.prototype.player = {
          _contract: ['bar'],
          foo: function() {
            return "Role method foo";
          }
        };

        Game.prototype.judge = {
          _contract: ['foo'],
          judgeGame: function() {
            return "Judge: " + this.foo();
          }
        };

        Game.prototype.play = function() {
          return this.player.bar();
        };

        Game.prototype.playFoo = function() {
          return this.player.foo();
        };

        Game.prototype.judgeGame = function() {
          return this.judge.judgeGame();
        };

        return Game;

      })(Ivento.Dci.Context);
      it("should call the instance method of object.foo even if the object has a role.foo method defined, if called outside the context", function() {
        var game, person;
        person = {
          foo: function() {
            return "Object method foo";
          },
          bar: function() {
            return this.foo();
          }
        };
        game = new Game(person);
        expect(game.play()).toEqual("Object method foo");
        expect(game.playFoo()).toEqual("Role method foo");
        expect(game.judgeGame()).toEqual("Judge: Object method foo");
        expect(person.foo()).toEqual("Object method foo");
        return expect(person.bar()).toEqual("Object method foo");
      });
      it("should call the role method role.foo even if the object has a object.foo defined, if called inside the context", function() {
        var dbAccount, logAccount;
        dbAccount = new DbAccount(123);
        logAccount = new LogAccount(dbAccount);
        expect(dbAccount.logWritten).toBeFalsy();
        expect(dbAccount.dbWritten).toBeFalsy();
        logAccount.transfer();
        expect(dbAccount.logWritten).toBeTruthy();
        return expect(dbAccount.dbWritten).toBeTruthy();
      });
      return it("should call methods depending on what role they were called from", function() {
        var context;
        context = new MultiRoles;
        return expect(context.doIt()).toEqual("sourcetarget");
      });
    });
    return describe("Unbinding behavior", function() {
      var SpiderMan, SuperMan, man, superMan;
      man = null;
      superMan = null;
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
            expect(this).toBe(man);
            return "wheee!";
          }
        };

        SuperMan.prototype.execute = function() {
          expect(this).toBe(superMan);
          return this.superman.fly();
        };

        SuperMan.prototype.xRay = function() {
          return this.superman.useXRay();
        };

        return SuperMan;

      })(Ivento.Dci.Context);
      return it("should prevent access to Roles outside the Context.", function() {
        superMan = new SuperMan(man);
        expect(man.useXRay()).toEqual("Prevented by glasses.");
        expect(man.fly).toBeUndefined();
        expect(superMan.xRay()).toEqual("wzzzt!");
        return expect(superMan.superman.name).toBeUndefined();
      });
    });
  });

}).call(this);
