describe "Ivento.Dci.Context", ->

	class Account extends Ivento.Dci.Context
		constructor: (entriesArray) ->
			@bind(entries: entriesArray).to(@ledgers)

		ledgers:
			addEntry: (message, amount) ->
				@entries.push message: message, amount: amount
			getBalance: () ->
				@entries.reduce ((prev, curr) -> prev + curr.amount), 0
		
		balance: () -> @ledgers.getBalance()

		increaseBalance: (amount) ->
			@ledgers.addEntry "Depositing", amount

		decreaseBalance: (amount) ->
			@ledgers.addEntry "Withdrawing", -amount

	class SimplerAccount
		constructor: (entriesArray) ->
			Ivento.Dci.Context.bind(@, entries: entriesArray).to(@ledgers)

		ledgers:
			getBalance: () ->
				@entries.reduce ((prev, curr) -> prev + curr.amount), 0
		
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
