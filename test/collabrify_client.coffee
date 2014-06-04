require './chai'
Collabrify = require '../collabrify'
CollabrifyClient = require '../collabrify_client'
Long = require 'long'

describe 'CollabrifyClient', ->

	before ->
		@client = new CollabrifyClient
			application_id: Long.fromString('4891981239025664')
			user_id: 'collabrify.tester@gmail.com'

	it 'should register and emit events', (done) ->
		@client.on 'custom_event', -> 
			done()
		@client.eventEmitter.emit('custom_event')

	it 'should initialize with properties', ->
		#@client.application_id.should.equal Long.fromString('4891981239025664')
		@client.user_id.should.equal 'collabrify.tester@gmail.com'
	
	it 'should make a succesfull warmup request', (done) ->
		@client.on 'ready', ->
			done()
		@client.on 'error', (error) ->

	it 'should broadcast message', (done) ->
		this.timeout(6000)
		c = new CollabrifyClient
			application_id: Long.fromString('4891981239025664')
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: false
		c.on 'notifications_start', ->
			c.broadcast deep: 'potlee'
		c.on 'event', (event) ->
			event.data.deep.should.equal 'potlee'
			done()
		c.on 'notifications_error', (error) ->
			throw error
		c.onerror 'broadcast', ->
			throw error

	it 'should start notifications', (done) ->
		this.timeout(3000)
		c = new CollabrifyClient
			application_id: Long.fromString('4891981239025664')
			user_id: 'collabrify.tester@gmail.com'
		c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		c.ondone 'create_session', (session) =>
			session.should.exist
		c.on 'notifications_start', ->
			done()
		c.on 'notifications_error', (error) ->
			throw error

	it 'should create session', (done) ->
		@client.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		@client.ondone 'create_session', (session) =>
			session.session_name.split('_').should.have.length 3
			session.session_tag[0].should.equal 'node_test_session'
			@client.session.session_tag[0].should.equal 'node_test_session'
			done()
		@client.on 'notifications_start', ->
			#alert 'start'
		@client.on 'notifications_error', (error) ->
			alert 'internet turned off'

	it 'should create session with basefile and join it', (done) ->
		@timeout 20000
		tag = 'node_test_session' + Math.random().toString()
		@client.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: [tag]
			startPaused: false
			baseFile: {this: 'is', a: 'basefile'}

		@client.ondone 'create_session', =>
			@client.listSessions [tag]
		
		@client.ondone 'list_sessions', (list) =>
			console.log list[0]
			@client.joinSession 
				session: list[0]
				password: 'password'

		@client.ondone 'join_session', (session) ->
			session.baseFile.a.should.equal 'basefile'


	it 'should look for sessions with tags', (done) ->
		unless window?
			console.log 'not testable on node'
			done()
		else
			@client.listSessions ['node_test_session']
			@client.ondone 'list_sessions', (list) ->
				list.should.be.an 'Array'
				done()
			@client.onerror 'list_sessions', (error) ->
				error.should.not.exist()

	# it 'should be able to prevent further joins', (done) ->
	# 	@client.createSession
	# 		name: 'node_test_session' + Math.random().toString()
	# 		password: 'password' 
	# 		tags: ['node_test_session']
	# 		startPaused: false
	# 	@client.preventFutureJoins

	# 	@client.on 'prevent_future_joins_done', ->

