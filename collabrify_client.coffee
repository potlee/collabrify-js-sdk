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
			@eventEmitter.emit 'error', e
	
	@version: Collabrify.ClientVersion
		
	accessInfo: ->
		accessInfo = new Collabrify.AccessInfo
			application_id: @application_id
			user_id: @user_id
		if @session
			if @sessionPassword then accessInfo.session_password = @sessionPassword
			accessInfo.session_id = @session.session_id || null 
			accessInfo.participant_id = @session.participant_id && @session.participant_id[0] || null 
		accessInfo
		
	broadcast: (event_data, event_type) ->
		new Promise (fulfill, reject) =>
			srid = @submission_registration_id++
			if event_data.toString() == '[object ArrayBuffer]'
				buffer = event_data
			else
				buffer = ByteBuffer.wrap(JSON.stringify(event_data)).toBuffer()
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
					addResponse = Collabrify.AddEventResponse.decodeDelimited(buf)
					broadcastedEvent = Collabrify.createEvent({
						order_id: addResponse.new_event_order_id, 
						raw: buffer, 
						timestamp: addResponse.timestamp, 
						srid: addResponse.submission_registration_id, 
						author: @participant, 
						type: event_type, 
						timeAdjustment: @timeAdjustment})
					fulfill(broadcastedEvent)
					console.log 'from broadcast'
					@eventEmitter.emitOrdered 'event', broadcastedEvent

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
					session_password: @sessionPassword || null
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
			if options.password
				a.session_password = options.password
				@sessionPassword = options.password
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
								@session.baseFile = JSON.parse(buf.readUTF8StringBytes(buf.remaining()))
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

	listSessions: (tags, exactMatch = false) ->
		
		new Promise (fulfill, reject) =>
			Collabrify.request
				header: 'LIST_SESSIONS_REQUEST'
				reject: reject

				body: new Collabrify.ListSessionsRequest
					access_info: @accessInfo()
					session_tag: tags
					flag__use_tags_as_filters: !exactMatch

				ondone: (buf) =>
					list = Collabrify.ListSessionsResponse.decodeDelimited(buf)
					fulfill(list.session)

	on: (e,c) ->
		@eventEmitter.on e, c

	subscribeToChannel: (channel) =>
		channel = new goog.appengine.Channel(channel)
		@session.socket = channel.open()
		
		@session.socket.onopen = (open) =>
			@eventEmitter.emit 'notifications_start'
		
		@session.socket.onmessage = (message) =>
			try
				return unless @session 
				notification = Collabrify.CollabrifyNotification.decode64(message.data)
				if notification.notification_message_type == 1 #Collabrify.NotificationMessageType['ADD_EVENT_NOTIFICATION']
					addEvent = Collabrify.Notification_AddEvent.decode64(notification.payload)
					if addEvent.author_participant_id == @participant.participant_id
						#event already processed, no need to do anything here
						return
					if addEvent.flag__event_included	
						@eventEmitter.emitOrdered 'event', Collabrify.createEvent({
							order_id: addEvent.order_id, 
							raw: addEvent.event.payload.toBuffer(), 
							timestamp: addEvent.event.timestamp, 
							srid: -1, 
							author: @session.participant[addEvent.author_participant_id], 
							type: addEvent.event.event_type, 
							timeAdjustment: @timeAdjustment})
					else
						#fetch event manually
						Collabrify.request
							header: 'GET_EVENT_BATCH_REQUEST'

							body: new Collabrify.GetEventBatchRequest
								access_info: @accessInfo()
								starting_order_id: addEvent.order_id
								ending_order_id: -1 #Get all remaining events
							
							ondone: (buf) =>
								body = Collabrify.GetEventBatchResponse.decodeDelimited(buf)
								if body.number_of_events_to_follow
									for i in [1..body.number_of_events_to_follow] 
										eventPB = Collabrify.Event.decodeDelimited(buf)
										unless eventPB.author_participant_id == @participant.participant_id 
											event = Collabrify.createEvent({
												order_id: eventPB.order_id, 
												raw: eventPB.payload.toBuffer(), 
												timestamp: eventPB.timestamp,
												srid: -1, 
												author: @session.participant[eventPB.author_participant_id], 
												type: eventPB.event_type, 
												timeAdjustment: @timeAdjustment})
											@eventEmitter.emitOrdered 'event', event

				if notification.notification_message_type == 2 #Collabrify.NotificationMessageType['ADD_PARTICIPANT_NOTIFICATION']
					addParticipant = Collabrify.Notification_AddParticipant.decode(notification.payload)
					@session.participant[addParticipant.participant.participant_id] = addParticipant.participant
					@eventEmitter.emit 'user_joined', addParticipant.participant

				if notification.notification_message_type == 3 #Collabrify.NotificationMessageType['END_SESSION_NOTIFICATION']
					@reset()
					@eventEmitter.emit 'sesson_ended', @session

				if notification.notification_message_type == 4 #Collabrify.NotificationMessageType['REMOVE_PARTICIPANT_NOTIFICATION']
					removeParticipant = Collabrify.Notification_RemoveParticipant.decode64(notification.payload)
					if @catchup_participant_ids
						@catchup_participant_ids[removeParticipant.particpant.participant_id] = null
					delete @session.participant[removeParticipant.particpant.participant_id]
					@eventEmitter.emit 'user_left', removeParticipant.particpant

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
							ending_order_id: -1 #Get all remaining events
						
						ondone: (buf) =>
							body = Collabrify.GetEventBatchResponse.decodeDelimited(buf)
							if body.number_of_events_to_follow
								for i in [1..body.number_of_events_to_follow] 
									eventPB = Collabrify.Event.decodeDelimited(buf)
									unless eventPB.author_participant_id == @participant.participant_id 
										event = Collabrify.createEvent({
											order_id: eventPB.order_id, 
											raw: eventPB.payload.toBuffer(), 
											timestamp: eventPB.timestamp,
											srid: -1, 
											author: @session.participant[eventPB.author_participant_id], 
											type: eventPB.event_type, 
											timeAdjustment: @timeAdjustment})
										console.log 'channel connected notfy'
										@eventEmitter.emitOrdered 'event', event
			catch e
				@eventEmitter.emit 'error', e
				
		@session.socket.onerror = (error) =>
			#close socket and reconnect if still in session
			return unless @session
			@reconnectChannel()
					
		@session.socket.onclose = (close) =>
			@eventEmitter.emit 'notifications_close'

	reconnectChannel: ->
		@session.socket.close()
		Collabrify.request
			header: 'UPDATE_NOTIFICATION_ID_REQUEST'
			reject: (error) =>
				#reconnect failed, reset and emit error
				@reset()
				error = new Error(error.description || "notifications error")
				@eventEmitter.emit 'error', error
				
			body: new Collabrify.UpdateNotificationIdRequest
				access_info: @accessInfo()
				participant_notification_medium_type: 1
				
			ondone: (buf) =>
				body = Collabrify.UpdateNotificationIdResponse.decodeDelimited(buf)
				@participant = body.participant
				@session = body.session
				participantsHash = {}
				(participantsHash[p.participant_id] = p) for p in @session.participant
				@session.participant = participantsHash
				
				@subscribeToChannel @participant.notification_id

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
					to_be_removed_participant_id: @participant.participant_id

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
		if @session
			if @session.socket
				@session.socket.close()
			@session = undefined
		@participant = undefined
		@submission_registration_id = 1
		@sessionPassword = undefined
module.exports = CollabrifyClient