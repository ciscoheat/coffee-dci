describe "Ivento.Dci.Context", ->

	class Account extends Ivento.Dci.Context
		constructor: (entries = []) ->
			@bind(entries).to(@ledgers)

		# ===== Roles =====

		ledgers:
			addEntry: (message, amount) ->
				@push message: message, amount: amount

			getBalance: () ->
				@reduce ((prev, curr) -> prev + curr.amount), 0
		
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
			getBalance: () ->
				@entries.reduce ((prev, curr) -> prev + curr.amount), 0

		# ===== End roles =====
		
		balance: () -> @ledgers.getBalance()

	ctx = null
	entries = null

	beforeEach ->
		entries = [
			message: "Start", amount: 100
		,
			message: "First deposit", amount: 1000
		]

		ctx = new Account entries

	describe "Binding behaviour", ->

		it "should bind objects to roles using the bind() method", ->
			expect(ctx.ledgers).toBe(entries)
			expect(ctx.ledgers.getBalance()).toEqual(1100)

		it "should be able to use the context methods", ->
			expect(ctx.balance()).toEqual(ctx.ledgers.getBalance())

		it "should modify the rolePlayers correctly", ->
			expect(ctx.ledgers).toBe(entries)
			expect(ctx.ledgers.length).toBe(2)

			ctx.increaseBalance 200
			
			expect(ctx.ledgers).toBe(entries)
			expect(ctx.ledgers.length).toBe(3)
			expect(ctx.ledgers[2]).toEqual(message: "Depositing", amount: 200)
			expect(ctx.balance()).toEqual(1300)

			ctx.decreaseBalance 1500
			
			expect(ctx.balance()).toEqual(-200)
			expect(ctx.ledgers[3]).toEqual(message: "Withdrawing", amount: -1500)

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
				withdraw: (amount) -> 
					@decreaseBalance amount

				transfer: (amount) ->
					@context.destination.deposit amount
					@withdraw amount

			destination:
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
			amount = 200

			expect(src.balance()).toEqual(1100)
			expect(dest.balance()).toEqual(0)

			context = new MoneyTransfer src, dest, amount
			context.transfer()
			context.unbind()

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

		it "should ensure that the RolePlayer has all contract properties in the _contract array", ->
			person =
				name: "Henry"

			guests = []
			guests.add = guests.push
			guests.remove = (g) -> delete @[g]

			context = new Restaurant guests, person
			expect(context.waiter.greetGuests()).toEqual "Welcome, my name is Henry, I'll be your waiter tonight."
			expect(context.guests.add "Someone").toEqual 1

		it "should throw an Exception if the RolePlayer doesn't have all the properties in the _contract array", ->
			anonymous = {}

			guests = []
			guests.add = guests.push
			guests.remove = (g) -> delete @[g]

			expect(() -> new Restaurant guests, anonymous).toThrow "RolePlayer [object Object] didn't fulfill Role Contract with property 'name'."

	describe "Role method accessing behavior for name conflicts", ->

		class Game extends Ivento.Dci.Context
			constructor: (player) ->
				@bind(player).to(@player)

			player:
				_contract: ['bar']

				foo: () -> 
					"Role method foo"
					
			play: () ->
				@player.bar()

			playFoo: () ->
				@player.foo()

		class LogAccount extends Ivento.Dci.Context
			constructor: (account) ->
				@bind(account).to(@account)

			account:
				_contract: ['amount', 'save', 'write']

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

		it "should call the instance method of object.foo even if the object has a role.foo method defined, if called outside the context", ->

			person =
				foo: () -> "Object method foo"
				bar: () -> @foo()

			game = new Game person
			expect(game.play()).toEqual("Object method foo")
			expect(game.playFoo()).toEqual("Role method foo")

		it "should call the role method role.foo even if the object has a object.foo defined, if called inside the context", ->
			dbAccount = new DbAccount 123
			logAccount = new LogAccount dbAccount

			expect(dbAccount.logWritten).toBeFalsy()
			expect(dbAccount.dbWritten).toBeFalsy()

			logAccount.transfer()

			expect(dbAccount.logWritten).toBeTruthy()
			expect(dbAccount.dbWritten).toBeTruthy()

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

		it "should have an unbind method added after the first bind", ->
			spider = new SpiderMan man
			expect(spider.unbind).toBeUndefined()

			superMan = new SuperMan man
			expect(superMan.unbind).toBeDefined()

		it "should remove the role methods from the rolePlayer when calling unbind", ->
			superMan = new SuperMan man

			# Cannot use xRay outside context.
			expect(man.useXRay()).toEqual("Prevented by glasses.")
			expect(man.fly()).toEqual("wheee!")

			expect(superMan.superman.name).toBeDefined()
			expect(superMan.xRay()).toEqual("wzzzt!")

			superMan.unbind()

			expect(man.fly).toBeUndefined()
						
			expect(superMan.unbind).toBeUndefined()
			expect(superMan.superman.name).toBeUndefined()