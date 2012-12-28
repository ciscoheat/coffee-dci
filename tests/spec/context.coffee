describe "Ivento.Dci.Context", ->

	class Account extends Ivento.Dci.Context
		constructor: (entries = []) ->
			@bind(entries).to(@ledgers)
			@bind(entries).to(@balancer)

		# ===== Roles =====

		balancer:
			_contract: ['reduce']

			getBalance: () ->
				@reduce ((prev, curr) -> prev + curr.amount), 0

		ledgers:
			_contract: ['push']

			addEntry: (message, amount) ->
				@push message: message, amount: amount

			getBalance: () ->
				@context.balancer.getBalance()
		
		# ===== End roles =====

		balance: () -> 
			@ledgers.getBalance()

		increaseBalance: (amount) ->
			@ledgers.addEntry "Depositing", amount

		decreaseBalance: (amount) ->
			@ledgers.addEntry "Withdrawing", -amount


	class SimplerAccount
		constructor: (entriesArray) ->
			# Binding using the static method.
			Ivento.Dci.Context.bind(@, entries: entriesArray).to(@ledgers)

		# ===== Roles =====

		ledgers:
			_contract: ['entries']

			getBalance: () ->
				@entries.reduce ((prev, curr) -> prev + curr.amount), 0

		# ===== End roles =====
		
		balance: () -> @ledgers.getBalance()

	entries = null

	beforeEach ->
		entries = [
			message: "Start", amount: 100
		,
			message: "First deposit", amount: 1000
		]

		window.entries = entries

	describe "Binding behaviour", ->

		ctx = null

		beforeEach ->
			ctx = new Account entries

		it "should bind objects to roles using the bind() method", ->
			expect(ctx.ledgers).toBeDefined()

		it "should be able to use the context methods", ->
			expect(ctx.balance()).toEqual(1100)

		it "should modify the rolePlayers correctly", ->
			expect(entries.length).toBe(2)

			ctx.increaseBalance 200
			
			expect(entries.length).toBe(3)

			expect(entries[2]).toEqual(message: "Depositing", amount: 200)
			expect(ctx.balance()).toEqual(1300)

			ctx.decreaseBalance 1500
			
			expect(ctx.balance()).toEqual(-200)
			expect(entries[3]).toEqual(message: "Withdrawing", amount: -1500)

		it "should bind to objects not using inheritance with the static method.", ->
			simple = new SimplerAccount entries
			expect(simple.balance()).toEqual(1100)

	describe "MoneyTransfer Context", ->
		
		class MoneyTransfer extends Ivento.Dci.Context
			constructor: (source, destination, amount) ->
				@bind(source).to(@source)
				@bind(destination).to(@destination)
				@bind(amount).to(@amount)

			# ===== Roles =====

			source:
				_contract: ['decreaseBalance']

				withdraw: (amount) -> 
					@decreaseBalance amount

				transfer: (amount) ->
					@context.destination.deposit amount
					@context.source.withdraw amount

			destination:
				_contract: ['increaseBalance']

				deposit: (amount) -> 
					@increaseBalance amount

			amount: 
				{}

			# ===== End roles =====

			transfer: () -> 
				@source.transfer @amount

		it "should transfer money using Accounts", ->
			
			src = new Account entries
			dest = new Account

			expect(src.balance()).toEqual(1100)
			expect(dest.balance()).toEqual(0)

			context = new MoneyTransfer src, dest, 200
			context.transfer()
			#context.unbind()

			expect(src.balance()).toEqual(900)
			expect(dest.balance()).toEqual(200)

	describe "Role Contracts", ->

		class Restaurant extends Ivento.Dci.Context
			constructor: (guests, waiter) ->
				@bind(guests).to(@guests)
				@bind(waiter).to(@waiter)

			waiter:
				_contract: ['name']

				greetGuests: () ->
					"Welcome, my name is " + @name + ", I'll be your waiter tonight."

			guests:
				_contract: ['add', 'remove']

			greet: () ->
				@waiter.greetGuests()

			addGuest: (name) ->
				@guests.add name

		it "should ensure that the RolePlayer has all contract properties in the _contract array", ->
			person =
				name: "Henry"

			guests = []
			guests.add = guests.push
			guests.remove = (g) -> delete @[g]

			context = new Restaurant guests, person
			expect(context.greet()).toEqual "Welcome, my name is Henry, I'll be your waiter tonight."
			expect(context.addGuest "Someone").toEqual 1

		it "should throw an Exception if the RolePlayer doesn't have all the properties in the _contract array", ->
			anonymous = {}

			guests = []
			guests.add = guests.push
			guests.remove = (g) -> delete @[g]

			expect(() -> new Restaurant guests, anonymous).toThrow "RolePlayer [object Object] didn't fulfill Role Contract with property 'name'."

	describe "Role method accessing behavior for name conflicts", ->

		class LogAccount extends Ivento.Dci.Context
			constructor: (account) ->
				@bind(account).to(@account)

			account:
				_contract: ['save', 'write']

				transfer: () ->
					@save()
					@write()

				write: () ->
					@logWritten = true

			transfer: () ->
				@account.transfer()

		class DbAccount
			constructor: (@amount) ->
				
			save: () =>
				@write() if @validate()

			validate: () =>
				@amount > 0

			write: () =>
				@dbWritten = true

		class MultiRoles extends Ivento.Dci.Context
			constructor: (object = {}) ->
				@bind(object).to(@source)
				@bind(object).to(@target)

			source:
				foo: () -> "source"

			target:
				foo: () -> "target"

			doIt: () ->
				@source.foo() + @target.foo()

		class Game extends Ivento.Dci.Context
			constructor: (player) ->
				@bind(player).to(@player)
				@bind(player).to(@judge)

			player:
				_contract: ['bar']

				foo: () -> 
					"Role method foo"

			judge:
				_contract: ['foo']

				judgeGame: () ->
					"Judge: " + @foo()
					
			play: () ->
				@player.bar()

			playFoo: () ->
				@player.foo()

			judgeGame: () ->
				@judge.judgeGame()

		it "should call the instance method of object.foo even if the object has a role.foo method defined, if called outside the context", ->

			person =
				foo: () -> "Object method foo"
				bar: () -> @foo()

			game = new Game person

			expect(game.play()).toEqual("Object method foo")
			expect(game.playFoo()).toEqual("Role method foo")
			expect(game.judgeGame()).toEqual("Judge: Object method foo")

			expect(person.foo()).toEqual("Object method foo")
			expect(person.bar()).toEqual("Object method foo")

		it "should call the role method role.foo even if the object has a object.foo defined, if called inside the context", ->
			dbAccount = new DbAccount 123
			logAccount = new LogAccount dbAccount

			expect(dbAccount.logWritten).toBeFalsy()
			expect(dbAccount.dbWritten).toBeFalsy()

			logAccount.transfer()

			expect(dbAccount.logWritten).toBeTruthy()
			expect(dbAccount.dbWritten).toBeTruthy()

		it "should call methods depending on what role they were called from", ->
			
			context = new MultiRoles
			expect(context.doIt()).toEqual("sourcetarget")

	describe "Unbinding behavior", ->
		
		man = null
		superMan = null

		beforeEach ->
			man = 
				name: "Clark Kent"
				useXRay: () -> "Prevented by glasses."

		class SpiderMan extends Ivento.Dci.Context
			constructor: (man) ->
				# No bindings, so no unbind is added to Context object.

			spiderman:
				useWeb: () -> "fzzzt!"

		class SuperMan extends Ivento.Dci.Context
			constructor: (man) ->
				@bind(man).to(@superman)

			superman:
				useXRay: () -> "wzzzt!"

				fly: () -> 
					# Testing for equality with roleplayer
					expect(@).toBe(man)
					"wheee!"

			execute: () -> 
				# Testing for equality with context
				expect(@).toBe(superMan)
				@superman.fly()

			xRay: () -> 
				@superman.useXRay()

		it "should prevent access to Roles outside the Context.", ->
			superMan = new SuperMan man

			# Cannot use xRay outside context.
			expect(man.useXRay()).toEqual("Prevented by glasses.")
			expect(man.fly).toBeUndefined()
			expect(superMan.xRay()).toEqual("wzzzt!")
			# Does not work with Iced Coffeescript:
			#expect(-> superMan.superman.fly()).toThrow "Access to Role 'superman.fly' from outside Context."
			expect(superMan.superman.name).toBeUndefined()