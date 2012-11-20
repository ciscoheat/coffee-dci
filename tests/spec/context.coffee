describe "Ivento.Dci.Context", ->

	describe "Static methods", ->

		xit "should return the parameter names correctly from a function", ->
			f = (a, bb, ccc, dddd) -> true
			expect(Ivento.Dci.Context.paramNames f).toEqual(["a", "bb", "ccc", "dddd"])
	
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
