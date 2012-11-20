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

	describe "Binding behaviour", ->

		beforeEach ->
			entries = [
				message: "Start", amount: 100
			,
				message: "First deposit", amount: 1000
			]

			ctx = new Account entries

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
					@context.source.withdraw amount

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
