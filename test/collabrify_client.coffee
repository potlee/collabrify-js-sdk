require './chai'
ProtoBuf = require "../ProtoBuf.js"
CollabrifyClient = require '../collabrify_client'
builder = ProtoBuf.loadProtoFile "../proto/CollabrifyProtocolBuffer.proto"
CollabrifyNotification = builder.build 'CollabrifyNotification_PB'
Notification_AddParticipant = builder.build 'Notification_AddParticipant_PB'
Notification_RemoveParticipant = builder.build 'Notification_RemoveParticipant_PB'
Participant = builder.build 'Participant_PB'

describe 'CollabrifyClient', ->

	beforeEach ->
		@c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'

	afterEach ->
		if(@c.session)
			@c.leaveSession()
		@c = null
		
	it 'should register and emit events', (done) ->
		@c.on 'custom_event', -> 
			done()
		@c.eventEmitter.emit('custom_event')

	it 'should initialize with properties', ->
		#@c.application_id.should.equal Long.fromString('4891981239025664')
		@c.user_id.should.equal 'collabrify.tester@gmail.com'
	
	it 'should make a succesfull warmup request', (done) ->
		@c.on 'ready', ->
			done()
		@c.on 'error', (error) ->
			done(error)

	it 'should broadcast message', (done) ->
		this.timeout(3000)
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: false
		.catch (error) ->
			done(error)
		@c.on 'notifications_start', =>
			@c.broadcast deep: 'potlee'
			.catch (e) ->
				done(e)
		@c.on 'event', (event) ->
			event.data().deep.should.equal 'potlee'
			done()
		@c.on 'notifications_error', (error) ->
			done(error)

	it 'should create session', (done) ->
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then (session) =>
			session.session_name.split('_').should.have.length 3
			session.session_tag[0].should.equal 'node_test_session'
			@c.session.session_tag[0].should.equal 'node_test_session'
			done()
		@c.on 'notifications_start', ->
			#alert 'start'
		@c.on 'notifications_error', (error) ->
			done(error)

	it 'should create session with basefile and join it', (done) ->
		@timeout 10000
		tag = 'node_test_session' + Math.random().toString()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: [tag]
			startPaused: false
			baseFile: {aa: Array(20).join('a'), bb: Array(1024*900).join('b'), a: 'basefile'}
		.then (session) =>
			@c.listSessions [tag]	
		.then (list) =>
			@c.joinSession 
				session: list[0]
				password: 'password'
		.then (session) ->
			session.baseFile.a.should.equal 'basefile'
			console.log session.baseFile
			#session.baseFile.aa[999].should.equal 'p'
			done()
		.catch (e) ->
			done(e)

	it 'should look for sessions with tags', (done) ->
		@timeout 4000
		@c.listSessions ['node_test_session']
		.then (list) ->
			list.should.be.an 'Array'
			done()
		.catch (e) ->
			done(e)

	it 'should leave session', (done) ->
		@timeout 3000
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then =>
			@c.leaveSession()
		.then =>
			String(@c.session).should.equal 'undefined'
			done()
		.catch (e) ->
			done(e)

	it 'should end session', (done) ->
		@timeout 3000
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then =>
			@c.endSession()
		.then =>
			String(@c.session).should.equal 'undefined'
			done()
		.catch (e) ->
			done(e)

	it 'should prevent further joins', (done) ->
		@timeout 5000
		tag = 'node_test_session' + Math.random().toString()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: [tag]
			startPaused: false
			baseFile: {this: 'is', a: 'basefile'}
		.then =>
			@c.preventFurtherJoins()
		.then ->
			done()
		.catch (e) ->
			done(e)

	it 'should start notifications', (done) ->
		this.timeout(5000)
		@c.on 'notifications_start', ->
			done()
		@c.on 'notifications_error', (error) ->
			done(error)
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false

	it 'should add participant', (done) ->
		this.timeout(5000)
		participant = new Participant
			participant_id: 1234
			
		addParticipantNotfication = new Notification_AddParticipant
			participant_id: participant.participant_id
			participant: participant
			
		addParticipantWrapper = new CollabrifyNotification
			notification_message_type: 2 #Collabrify.NotificationMessageType['ADD_PARTICIPANT_NOTIFICATION']
			payload: addParticipantNotfication.encode().toBuffer()
				
		@c.on 'notifications_start', =>
			@c.session.socket.onmessage {data: addParticipantWrapper.toBase64()}
		@c.on 'user_joined', (joined_participant) ->
			if(joined_participant.participant_id.equals participant.participant_id)
				done()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false

	it 'should remove participant', (done) ->
		this.timeout(5000)
		participant = new Participant
			participant_id: 1234
			
		addParticipantNotfication = new Notification_AddParticipant
			participant_id: participant.participant_id
			participant: participant
			
		addParticipantWrapper = new CollabrifyNotification
			notification_message_type: 2 #Collabrify.NotificationMessageType['ADD_PARTICIPANT_NOTIFICATION']
			payload: addParticipantNotfication.encode().toBuffer()
		
		removeParticipantNotification = new Notification_RemoveParticipant
			particpant: participant
		
		removeParticipantWrapper = new CollabrifyNotification
			notification_message_type: 4 #Collabrify.NotificationMessageType['REMOVE_PARTICIPANT_NOTIFICATION']
			payload: removeParticipantNotification.encode().toBuffer()
		@c.on 'notifications_start', =>
			@c.session.socket.onmessage {data: addParticipantWrapper.toBase64()}
			@c.session.socket.onmessage {data: removeParticipantWrapper.toBase64()}
		@c.on 'user_left', (removed_participant) ->
			if(removed_participant.participant_id.equals participant.participant_id)
				done()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
			
	it 'should reconnect on channel error', (done) ->
		this.timeout(5000)
		@c.eventEmitter.once 'notifications_start', =>
			console.log 'first notification start'
			@c.on 'notifications_start', ->
				console.log 'second notification start'
				done()
			@c.session.socket.onerror('error')
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
			