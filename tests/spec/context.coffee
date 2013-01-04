describe "Ivento.Dci.Context", ->

	class Account extends Ivento.Dci.Context
		constructor: (entries = []) ->
			@bind(entries).to('ledgers')

		# ===== Roles =====

		ledgers:
			_contract: ['push', 'reduce']

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
			Ivento.Dci.Context.bind(@, entries: entriesArray).to('ledgers')

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

		it "should throw an exception if the Role name isn't found in the Context", ->
			
			class NoRoleFound extends Ivento.Dci.Context
				constructor: () ->
					@bind(123).to('nonExistentRole')

			expect(-> new NoRoleFound).toThrow("Role 'nonExistentRole' not found in Context.")

		it "should throw an exception if the Role isn't bound as a string", ->
			
			class NoStringBinding extends Ivento.Dci.Context
				constructor: () ->
					@bind(123).to(@role)

				role:
					{}

			expect(-> new NoStringBinding).toThrow("A Role must be bound as a string literal.")

		it "should be allowed to bind null to a Role", ->
			
			class NullBind extends Ivento.Dci.Context
				constructor: (o) ->
					@bind(o).to('role')

				role:
					_contract: ['test']

				test: () ->
					@role

			expect(new NullBind(null).test()).toBeNull()

	describe "MoneyTransfer with nested Contexts", ->
		
		class MoneyTransfer extends Ivento.Dci.Context
			constructor: (source, destination, amount) ->
				@bind(source).to('source')
				@bind(destination).to('destination')
				@bind(amount).to('amount')

			# ===== Roles =====

			source:
				_contract: ['decreaseBalance']

				withdraw: (amount) -> 
					@decreaseBalance amount

				transfer: (amount) ->
					@context.destination.deposit amount
					@withdraw amount

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
				@bind(guests).to('guests')
				@bind(waiter).to('waiter')

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

		it "should throw an Exception if the RolePlayer doesn't have all the properties specified in the contract", ->
			anonymous = {}

			guests = []
			guests.add = guests.push
			guests.remove = (g) -> delete @[g]

			expect(() -> new Restaurant guests, anonymous).toThrow "RolePlayer [object Object] didn't fulfill Role Contract with property 'name'."

		it "should throw an Exception if the RolePlayer doesn't have the nested properties specified in the contract", ->
			
			class NestedContract extends Ivento.Dci.Context
				constructor: (node) ->
					@bind(node).to('node')

				node:
					_contract: ['distance.from.east']

			noGoodNode = distance: 123
			goodNode = distance: from: east: 123

			expect(-> new NestedContract noGoodNode).toThrow "RolePlayer [object Object] didn't fulfill Role Contract with property 'distance.from.east'."
			expect(-> new NestedContract goodNode).not.toThrow()

		it "should throw an Exception if the contract specifies that the RolePlayer should be a function and it's not.", ->

			class FunctionContract extends Ivento.Dci.Context
				constructor: (o) ->
					@bind(o).to('funcRole')

				funcRole:
					_contract: ['()', 'field']

			test = field: "I'm a property"

			test2 = () -> "I'm a function"
			test2.field = "I'm a property"

			expect(-> new FunctionContract test).toThrow "RolePlayer [object Object] didn't fulfill Role Contract: Not a function."
			expect(-> new FunctionContract test2).not.toThrow()

	describe "Role method accessing behavior for name conflicts", ->

		class LogAccount extends Ivento.Dci.Context
			constructor: (account) ->
				@bind(account).to('account')

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

		class Game extends Ivento.Dci.Context
			constructor: (player) ->
				@bind(player).to('player')
				@bind(player).to('judge')

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

		it "should throw an exception if multiple roles have the same role method name", ->

			class ConflictRoleMethodNames extends Ivento.Dci.Context
				constructor: (object = {}) ->
					@bind(object).to('source')
					@bind(object).to('target')

				source:
					foo: () -> "source"

				target:
					foo: () -> "target"

				doIt: () ->
					@source.foo() + @target.foo()

			expect(-> new ConflictRoleMethodNames()).toThrow "Method name conflict in Roles 'source.foo' and 'target.foo'. Please prepend the Role names to the methods to avoid conflict."

		it "should throw an exception if a reserved property is defined in the context", ->
			
			class ConflictContextProperties extends Ivento.Dci.Context
				constructor: (o = {}) ->
					@bind(o).to('role')

				role:
					{}

				promise: () ->
					"Reserved property."

			expect(-> new ConflictContextProperties()).toThrow "Property 'promise' is reserved in a Context object."

	describe "Context access from Role methods", ->
		
		class C1 extends Ivento.Dci.Context
			constructor: (o) ->
				@bind(o).to('R1')
				@bind("C1").to('name')

			# Role for testing object identity and context access
			R1:
				name: () ->
					@ + ":" + @context.name

			name:
				{}

			getName: () ->
				# Create a nested context
				c2 = new C2(@R1)

				# Test if the current context retains after creating a nested context
				output = @R1.name() + "/" 

				# Test of the nested context uses itself as current
				output += c2.getName()

				# Test if the nested context is unbound after calling a context method
				output += "/" + @R1.name()

		class C2 extends Ivento.Dci.Context
			constructor: (o) ->
				@bind(o).to('R2')
				@bind("C2").to('name')

			# Role for testing object identity and context access in a nested context
			R2:
				name: () ->
					@ + ":" + @context.name

			name:
				{}

			getName: () ->
				@R2.name()


		it "should access the correct context and objects should keep identity", ->
			a = toString: () -> "A"
			expect(new C1(a).getName()).toEqual("A:C1/A:C2/A:C1")

	describe "Role access from outside Context", ->

		class MethodScopeTest extends Ivento.Dci.Context
			constructor: (o) ->
				@bind(o).to('test')
    
			test:
				inside: () -> 
					"inside"
    
			doIt: () ->
				@test.inside()

		it "should not be allowed", ->
  
			o = outside: () -> "outside"
			a = new MethodScopeTest o
  
			expect(a.test).toBeDefined()
			expect(-> a.test.inside()).toThrow("Object #<Object> has no method 'inside'")

			# Call Context Method to test automatic unbinding
			expect(a.doIt()).toEqual("inside")
			expect(-> a.test.inside()).toThrow("Object #<Object> has no method 'inside'")

	describe "Asynchronous behavior", ->

		class Async extends Ivento.Dci.Context
			constructor: (o) ->
				@bind(o).to('ajax')

			ajax:
				_contract: ['output']

				get: (cb) -> 
					self = @
					asyncOperation = () ->
						self.output += "ASYNC"
						cb()

					setTimeout asyncOperation, 5

				addOutput: (s) ->
					@output += s
					
			afterAsync: () ->
				@ajax.output += "After"

			doItAsync: () ->
				@ajax.get () => 
					throw "Promise should be defined" if not @promise?
					# Little hack to determine if jQuery or promiseJS
					if @promise.always? then @promise.resolve() else @promise.done()

				@afterAsync()
				@promise

			returnPromise: () ->
				@ajax.output += "Return"

				@promise.then => 
					@ajax.addOutput "Promise"

				@promise

			customPromise: () ->
				# Don't use the promise in the Context
				p = jQuery.Deferred()

				p.then =>
					@ajax.addOutput "CustomPromise"

				p

		o = null

		beforeEach ->
			o = output: ""

		it "should unbind a Context Method if a promise is returned from it and completed", ->			

			runs ->
				a = new Async o
				a.doItAsync()

			waitsFor -> 
				o.output.length > 5
			, 
				50

			runs ->
				expect(o.output).toEqual("AfterASYNC")

		it "should not unbind the Context Methods if a promise is returned and not completed", ->
			
			a = new Async o
			p = a.returnPromise()

			expect(o.output).toEqual("Return")
			expect(o.get).toBeDefined()

			runs ->
				# Using jQuery, which resolves using resolve()
				p.resolve()

			waitsFor ->
				o.output is "ReturnPromise"

			runs ->
				expect(o.get).toBeUndefined()

		it "should not unbind the Context Methods if a custome promise is returned and not completed", ->
			
			a = new Async o
			p = a.customPromise()

			expect(o.get).toBeDefined()

			runs ->	
				p.resolve()

			waitsFor ->
				o.output is "CustomPromise"

			runs ->
				expect(o.get).toBeUndefined()

		it "should be able to change promise framework by using an adapter", ->
			
			Context = Ivento.Dci.Context

			# Save old methods
			promise = Context.promise
			unbindPromise = Context.unbindPromise
			isPromise = Context.isPromise

			expect(Context.promise).not.toBe(Context.promiseJsAdapter.factory)
			expect(Context.unbindPromise).not.toBe(Context.promiseJsAdapter.unbind)
			expect(Context.isPromise).not.toBe(Context.promiseJsAdapter.identify)

			Context.setPromiseAdapter Context.promiseJsAdapter

			expect(Context.promise).toBe(Context.promiseJsAdapter.factory)
			expect(Context.unbindPromise).toBe(Context.promiseJsAdapter.unbind)
			expect(Context.isPromise).toBe(Context.promiseJsAdapter.identify)

			runs ->
				a = new Async o
				a.doItAsync()

			waitsFor -> 
				o.output.length > 5
			, 
				50

			runs ->
				expect(o.output).toEqual("AfterASYNC")
				# Restore old promise functionality
				Context.promise = promise
				Context.unbindPromise = unbindPromise
				Context.isPromise = isPromise

	describe "Unbinding behavior", ->
		
		man = null
		superMan = null

		beforeEach ->
			man = 
				name: "Clark Kent"
				useXRay: () -> "Prevented by glasses."

		class SuperMan extends Ivento.Dci.Context
			constructor: (man) ->
				@bind(man).to('superman')

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

		it "should remove the role methods from the rolePlayer automatically", ->
			superMan = new SuperMan man

			# Cannot use xRay outside context.
			expect(man.useXRay()).toEqual("Prevented by glasses.")
			expect(man.fly).toBeUndefined()

			expect(superMan.superman.name).toBeUndefined()
			expect(superMan.xRay()).toEqual("wzzzt!")
			expect(superMan.execute()).toEqual("wheee!")

			expect(man.fly).toBeUndefined()

		it "should remove special properties from the rolePlayer automatically", ->
			superMan = new SuperMan man

			expect(man.context).toBeUndefined()

			expect(superMan.execute()).toEqual("wheee!")

			expect(man.context).toBeUndefined()
