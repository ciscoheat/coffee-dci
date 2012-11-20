describe "Ivento.Dci.Context", ->

	class Account extends Ivento.Dci.Context
		constructor: (entriesArray = []) ->
			@bind(entries: entriesArray).to(@ledgers)

		# ===== Roles =====

		ledgers:
			addEntry: (message, amount) ->
				@entries.push message: message, amount: amount

			getBalance: () ->
				@entries.reduce ((prev, curr) -> prev + curr.amount), 0
		
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
			expect(ctx.ledgers.entries).toBe(entries)
			expect(ctx.ledgers.getBalance()).toEqual(1100)

		it "should be able to use the context methods", ->
			expect(ctx.balance()).toEqual(ctx.ledgers.getBalance())

		it "should modify the rolePlayers correctly", ->
			ctx.increaseBalance 200
			expect(ctx.balance()).toEqual(1300)

			ctx.decreaseBalance 1500
			expect(ctx.balance()).toEqual(-200)

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
					@context.source.withdraw amount # Also works with "@withdraw amount"

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

			expect(src.balance()).toEqual(900)
			expect(dest.balance()).toEqual(200)

	describe "Unbinding behavior", ->
		
		man = null

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
				fly: () -> "wheee!"

			execute: () -> @superman.fly()

		it "should have an unbind method added after the first bind", ->
			spider = new SpiderMan man
			expect(spider.unbind).toBeUndefined()

			superMan = new SuperMan man
			expect(superMan.unbind).toBeDefined()

		it "unbind() should remove the role methods from the rolePlayer", ->
			superMan = new SuperMan man

			expect(man.useXRay()).toEqual("wzzzt!")
			expect(man.fly()).toEqual("wheee!")

			superMan.unbind()

			expect(man.fly).toBeUndefined()
			expect(man.useXRay()).toEqual("Prevented by glasses.")
			expect(superMan.unbind).toBeUndefined()
