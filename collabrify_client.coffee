EventEmitter = require('./ordered_event_emitter');
Collabrify = require './collabrify'
ByteBuffer = Collabrify.ByteBuffer
goog = require './channel'
class CollabrifyClient
	constructor: (options) ->
		localStorage.user_id ||= 'ANONYMOUS_ID@' + Math.random().toString() #uuid.v1()
		@user_id = localStorage.user_id
		@display_name = 'ANONYMOUS'
		for key, value of options
			this[key] = value
		@eventEmitter = new EventEmitter()
		Collabrify.request.client = this
		@submission_registration_id = 1
		@warmupRequest()
		.then =>
			@eventEmitter.emit 'ready'
		.catch (e) =>
			@eventEmitter.emit 'error'

	accessInfo: ->
		accessInfo = new Collabrify.AccessInfo
			application_id: @application_id
			user_id: @user_id
		if @session
			accessInfo.session_password = @sessionPassword || null
			accessInfo.session_id = @session.session_id || null 
			accessInfo.participant_id = @session.participant_id && @session.participant_id[0] || null 
		accessInfo

	broadcast: (message, event_type) ->
		new Promise (fulfill, reject) =>
			#messageByteBuffer = new ByteBuffer()
			#messageByteBuffer.writeJSON message
			#messageBuffer = messageByteBuffer.toBuffer()
			srid = @submission_registration_id++
			if message.toString() == '[object ArrayBuffer]'
				buffer = message
			else
				buffer = ByteBuffer.wrap(JSON.stringify(message)).toBuffer()
			Collabrify.requestSynch
				header: 'ADD_EVENT_REQUEST'
				reject: reject

				body: new Collabrify.AddEventRequest
					access_info: @accessInfo()
					number_of_bytes_to_follow: buffer.byteLength#messageBuffer.byteLength
					submission_registration_id: srid
					event_type: event_type

				message: buffer#messageBuffer

				ondone: (buf) =>
					event = Collabrify.AddEventResponse.decodeDelimited(buf)
					event.data = message
					event.order_id = event.new_event_order_id
					event.event_type = event_type
					event.elapsed = => Date.now() - @timeAdjustment - event.timestamp
					event.author = @participant
					fulfill(event)
				event_type: event_type
				event: message
				submission_registration_id: srid


	createSession: (sessionProperties) ->
		new Promise (fullfill, reject) =>
			basefile_chunks = []
			if sessionProperties.baseFile
				messageBuffer = ByteBuffer.wrap(JSON.stringify(sessionProperties.baseFile)).toBuffer()
				for i in [0...Math.ceil(messageBuffer.byteLength / Collabrify.chunkSize)]
					basefile_chunks.push(messageBuffer.slice(
						i * Collabrify.chunkSize
						Math.min((i+1) * Collabrify.chunkSize, messageBuffer.byteLength)
					))
			@sessionPassword = sessionProperties.password

			Collabrify.request
				header: 'CREATE_SESSION_REQUEST'
				include_timestamp_in_response: true
				reject: reject

				body: new Collabrify.CreateSessionRequest
					access_info: @accessInfo()
					session_tag: sessionProperties.tags
					session_name: sessionProperties.name
					session_password: @sessionPassword
					owner_display_name: @display_name
					number_of_bytes_to_follow: if basefile_chunks[0] then basefile_chunks[0].byteLength
					flag__session_has_base_file: basefile_chunks.length
					flag__base_file_complete: (basefile_chunks.length < 2)
					owner_notification_medium_type: 1
					participant_limit: sessionProperties.participantLimit || 0

				message: basefile_chunks[0]

				ondone: (buf, header) =>
					@newSessionHandler(buf, 'create', header)
					unless basefile_chunks.length >= 2
						fullfill(@session)
					for chunk, i in basefile_chunks[1..]
						is_last = (chunk == basefile_chunks[basefile_chunks.length-1])
						Collabrify.requestSynch
							header: 'ADD_TO_BASE_FILE_REQUEST'
							reject: reject

							body: new Collabrify.AddToBaseFileRequest
								access_info: @accessInfo()
								number_of_bytes_to_follow: chunk.byteLength
								flag__base_file_complete: is_last

							message: chunk

							ondone: (buf) =>
								if is_last
									fullfill(@session)

	joinSession: (options) ->
		new Promise (fulfill, reject) =>
			@sessionPassword = options.password
			a = @accessInfo()
			a.session_id = options.session.session_id
			a.session_password = options.password
			Collabrify.request
				header: 'ADD_PARTICIPANT_REQUEST'
				include_timestamp_in_response: true
				reject: reject

				body: new Collabrify.AddParticipantRequest
					access_info: a
					participant_display_name: @display_name
					participant_notification_id: ''
					participant_notification_medium_type: 1

				ondone: (buf, header) =>
					@newSessionHandler(buf, 'join', header)
					if @session.base_file_size
						Collabrify.requestSynch
							header: 'GET_FROM_BASE_FILE_REQUEST'
							reject: reject

							body: new Collabrify.GetFromBaseFileRequest
								access_info: @accessInfo()
								start_position: 0
								length: @session.base_file_size

							ondone: (buf) =>
								response = Collabrify.GetFromBaseFileResponse.decodeDelimited(buf)
								@session.baseFile = buf.toJSON()
								fulfill(@session)
					else
						fulfill(@session)

	newSessionHandler: (buf, request_type, header) ->
		user = if request_type is 'create' then 'owner' else 'participant'
		if request_type == 'create'
			response = Collabrify.CreateSessionResponse.decodeDelimited(buf)
		else
			response = Collabrify.AddParticipantResponse.decodeDelimited(buf)

		@participant = response[user]
		@session = response.session
		participantsHash = {}
		(participantsHash[p.participant_id] = p) for p in @session.participant
		@session.participant = participantsHash

		@timeAdjustment = Date.now() - header.timestamp
		@subscribeToChannel(response[user].notification_id)

	listSessions: (tags) ->
		new Promise (fulfill, reject) =>
			Collabrify.request
				header: 'LIST_SESSIONS_REQUEST'
				reject: reject

				body: new Collabrify.ListSessionsRequest
					access_info: @accessInfo()
					session_tag: tags

				ondone: (buf) =>
					list = Collabrify.ListSessionsResponse.decodeDelimited(buf)
					fulfill(list.session)

	on: (e,c) ->
		@eventEmitter.on e, c

	subscribeToChannel: (channel) =>
		channel = new goog.appengine.Channel(channel)
		socket = channel.open()
		
		socket.onopen = (open) =>
			@eventEmitter.emit 'notifications_start'
		
		socket.onmessage = (message) =>
			return unless @session 
			notification = Collabrify.CollabrifyNotification.decode64(message.data)

			if notification.notification_message_type == 1 #Collabrify.NotificationMessageType['ADD_EVENT_NOTIFICATION']
				addEvent = Collabrify.Notification_AddEvent.decode64(notification.payload)
				event = addEvent.event
				
				event.submission_registration_id = addEvent.submission_registration_id
				unless addEvent.event.author_participant_id == @participant.participant_id
					addEvent.event.submission_registration_id = -1

				event.author = @session.participant[event.author_participant_id]
				event.data = -> event.payload.toJSON()
				event.rawData = -> event.payload.toBuffer()
				addEvent.event.elapsed = => Date.now() - @timeAdjustment - event.timestamp

				@eventEmitter.emitOrdered 'event', event

			if notification.notification_message_type == 2 #Collabrify.NotificationMessageType['ADD_PARTICIPANT_NOTIFICATION']
				addParticipant = Collabrify.Notification_AddParticipant.decode64(notification.payload)
				@session.participant[addParticipant.participant.participant_id] = addParticipant.participant
				@eventEmitter.emit 'user_joined', addParticipant.participant

			if notification.notification_message_type == 3 #Collabrify.NotificationMessageType['END_SESSION_NOTIFICATION']
				@reset()
				@eventEmitter.emit 'sesson_ended', @session

			if notification.notification_message_type == 4 #Collabrify.NotificationMessageType['REMOVE_PARTICIPANT_NOTIFICATION']
				removeParticipant = Collabrify.Notification_RemoveParticipant.decode64(notification.payload)
				if @catchup_participant_ids
					@catchup_participant_ids[removeParticipant.participant_id] = null
				@eventEmitter.emit 'user_left', removeParticipant.participant

			if notification.notification_message_type == 5 #Collabrify.NotificationMessageType['ON_CHANNEL_CONNECTED_NOTIFICATION']
				@catchup_participant_ids = {}
				response = Collabrify.Notification_OnChannelConnected.decode64(notification.payload)
				participantsHash = {}
				
				for participant_id in response.participant_id
					participantsHash[participant_id] = @session.participant[participant_id]
					unless @session.participant[participant_id]
						@catchup_participant_ids[participant_id] = true
						Collabrify.request
							header: 'GET_PARTICIPANT_REQUEST'

							body: new Collabrify.GetParticipantRequest
								access_info: @accessInfo()
								participant_id: [participant_id]

							ondone: (buf) =>
								body = Collabrify.GetParticipantResponse.decodeDelimited(buf)
								if @catchup_participant_ids[participant_id]
									@session.participant[participant_id] = body.participant[0]
				@session.participant = participantsHash
				# 	for participant in @session.participant

				Collabrify.request
					header: 'GET_EVENT_BATCH_REQUEST'

					body: new Collabrify.GetEventBatchRequest
						access_info: @accessInfo()
						starting_order_id: @eventEmitter.nextEvent
						ending_order_id: response.current_order_id.low
					
					ondone: (buf) =>
						body = Collabrify.GetEventBatchResponse.decodeDelimited(buf)
						if body.number_of_events_to_follow
							for i in [1..body.number_of_events_to_follow] 
								event = Collabrify.Event.decodeDelimited(buf)
								event.data = -> event.payload.toJSON()
								event.rawData = -> event.payload.toBuffer()
								@eventEmitter.emitOrdered 'event', event, event.order_id
				#@eventEmitter.nextEvent = response.current_order_id.low + 1

		socket.onerror = (error) =>
			@eventEmitter.emit 'error', new Error(error.description || "notificaitons error")
	
		socket.onclose = (close) =>
			@eventEmitter.emit 'notifications_close'

	warmupRequest: ->
		new Promise (fullfill, reject) =>
			Collabrify.request
				header: 'WARMUP_REQUEST'
				body: new Collabrify.WarmupRequest
				reject: reject
				ondone: =>
					fullfill() #@eventEmitter.emit 'ready'
	
	leaveSession: ->
		new Promise (fulfill, reject) =>
			Collabrify.request
				header: 'REMOVE_PARTICIPANT_REQUEST'
				reject: reject

				body: new Collabrify.RemoveParticipantRequest
					access_info: @accessInfo()
					to_be_removed_participant_id: @session.participant_id[0]

				ondone: (buf) =>
					response = Collabrify.RemoveParticipantResponse.decodeDelimited(buf)
					@reset()
					fulfill()

	endSession: ->
		new Promise (fulfill, reject) =>
			if(@currentUserOwnsSession())
				Collabrify.request
					header: 'END_SESSION_REQUEST'
					reject: reject

					body: new Collabrify.EndSessionRequest
						access_info: @accessInfo()

					ondone: (buf) =>
						response = Collabrify.EndSessionResponse.decodeDelimited(buf)
						@reset()
						fulfill()

			else
				reject new Error('user does not own session')

	preventFurtherJoins: ->
		new Promise (fulfill, reject) =>
			Collabrify.request
				header: 'PREVENT_FURTHER_JOINS_REQUEST'
				reject: reject

				body: new Collabrify.PreventFurtherJoinsRequest
					access_info: @accessInfo()
					session_id: @session.session_id

				ondone: (buf) =>
					fulfill()
					#Collabrify.RequestHeader.decodeDelimited(buf)

	pauseEvents: ->
		@pausedEvents = []
		@pausedEmit = @eventEmitter.emit
		@eventEmitter.emit = () =>
			@pausedEvents.push arguments

	resumeEvents: ->
		@eventEmitter.emit = @pausedEmit
		for event in @pausedEvents
			@eventEmitter.emit(event...)

	currentUserOwnsSession: ->
		@session.owner.participant_id.low == @participant.participant_id.low

	reset: ->
		@participantsHash = {}
		@session = undefined
		@participant = undefined
		@submission_registration_id = 1
		@sessionPassword = undefined

module.exports = CollabrifyClient