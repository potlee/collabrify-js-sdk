require './chai'
CollabrifyClient = require '../collabrify_client'

describe 'CollabrifyClient', ->

	before ->
		@client = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'

	it 'should register and emit events', (done) ->
		@client.on 'custom_event', -> 
			done()
		@client.eventEmitter.emit('custom_event')

	it 'should initialize with properties', ->
		#@client.application_id.should.equal Long.fromString('4891981239025664')
		@client.user_id.should.equal 'collabrify.tester@gmail.com'
	
	it 'should make a succesfull warmup request', (done) ->
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.on 'ready', ->
			done()
		c.on 'error', (error) ->
			throw error

	it 'should broadcast message', (done) ->
		this.timeout(3000)
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'

		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: false
		.catch alert
		c.on 'notifications_start', ->
			c.broadcast deep: 'potlee'
			.catch (e) ->
				throw e
		c.on 'event', (event) ->
			event.data().deep.should.equal 'potlee'
			done()
		c.on 'notifications_error', (error) ->
			throw error

	it 'should create session', (done) ->
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then (session) ->
			session.session_name.split('_').should.have.length 3
			session.session_tag[0].should.equal 'node_test_session'
			c.session.session_tag[0].should.equal 'node_test_session'
			done()
		c.on 'notifications_start', ->
			#alert 'start'
		c.on 'notifications_error', (error) ->
			alert 'internet turned off'

	it 'should create session with basefile and join it', (done) ->
		@timeout 10000
		tag = 'node_test_session' + Math.random().toString()
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: [tag]
			startPaused: false
			baseFile: {aa: Array(20).join('a'), bb: Array(1024*900).join('b'), a: 'basefile'}
		.then (session) ->
			c.listSessions [tag]	
		.then (list) ->
			c.joinSession 
				session: list[0]
				password: 'password'
		.then (session) ->
			session.baseFile.a.should.equal 'basefile'
			console.log session.baseFile
			#session.baseFile.aa[999].should.equal 'p'
			done()
		.catch (e) ->
			alert e

	it 'should look for sessions with tags', (done) ->
		@timeout 4000
		@client.listSessions ['node_test_session']
		.then (list) ->
			list.should.be.an 'Array'
			done()
		.catch (e) ->
			throw e

	it 'should leave session', (done) ->
		@timeout 3000
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then ->
			c.leaveSession()
		.then ->
			String(c.session).should.equal 'undefined'
			done()
		.catch (e) ->
			alert e

	it 'should end session', (done) ->
		@timeout 3000
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then ->
			c.endSession()
		.then ->
			String(c.session).should.equal 'undefined'
			done()
		.catch (e) ->
			alert e

	it 'should prevent further joins', (done) ->
		@timeout 5000
		tag = 'node_test_session' + Math.random().toString()
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: [tag]
			startPaused: false
			baseFile: {this: 'is', a: 'basefile'}
		.then ->
			c.preventFurtherJoins()
		.then ->
			done()
		.catch (e) ->
			alert e

	it 'should start notifications', (done) ->
		this.timeout(3000)
		c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false

		c.on 'notifications_start', ->
			done()
		c.on 'notifications_error', (error) ->
			alert error

	# it 'should be able to prevent further joins', (done) ->
	# 	@client.createSession
	# 		name: 'node_test_session' + Math.random().toString()
	# 		password: 'password' 
	# 		tags: ['node_test_session']
	# 		startPaused: false
	# 	@client.preventFutureJoins

	# 	@client.on 'prevent_future_joins_done', ->

