ByteBuffer = require 'bytebuffer'
ProtoBuf = require "./ProtoBuf.js"
http = require 'http'
#Live
builder = ProtoBuf.loadProtoFile "http://collabrify-client-js.appspot.com/static/proto/CollabrifyProtocolBuffer.proto"
#Local
#builder = ProtoBuf.loadProtoFile "../proto/CollabrifyProtocolBuffer.proto"

RequestType = builder.build "CollabrifyRequestType_PB"
module.exports.RequestType = RequestType
RequestHeader = builder.build 'CollabrifyRequest_PB'
module.exports.RequestHeader = RequestHeader
ResponseHeader = builder.build 'CollabrifyResponse_PB'  
module.exports.ResponseHeader = ResponseHeader 
module.exports.WarmupRequest = builder.build "Request_Warmup_PB" 
module.exports.AccessInfo = builder.build 'AccessInfo_PB' 
module.exports.CreateSessionRequest = builder.build "Request_CreateSession_PB" 
module.exports.CreateSessionResponse = builder.build 'Response_CreateSession_PB' 
module.exports.ListSessionsRequest = builder.build 'Request_ListSessions_PB' 
module.exports.ListSessionsResponse = builder.build 'Response_ListSessions_PB'
module.exports.PreventFurtherJoinsRequest = builder.build 'Request_PreventFurtherJoins_PB'
module.exports.AddEventRequest = builder.build 'Request_AddEvent_PB'
module.exports.AddEventResponse = builder.build 'Response_AddEvent_PB'
module.exports.CollabrifyNotification = builder.build 'CollabrifyNotification_PB'
module.exports.Notification_AddEvent = builder.build 'Notification_AddEvent_PB'
module.exports.Notification_AddParticipant = builder.build 'Notification_AddParticipant_PB'
module.exports.Notification_RemoveParticipant = builder.build 'Notification_RemoveParticipant_PB'
module.exports.Notification_OnChannelConnected = builder.build 'Notification_OnChannelConnected_PB'
module.exports.NotificationMessageType = builder.build 'NotificationMessageType_PB'
module.exports.AddParticipantRequest = builder.build 'Request_AddParticipant_PB'
module.exports.AddParticipantResponse = builder.build 'Response_AddParticipant_PB'
module.exports.GetParticipantRequest = builder.build 'Request_GetParticipant_PB'
module.exports.GetParticipantResponse = builder.build 'Response_GetParticipant_PB'
module.exports.GetEventBatchRequest = builder.build 'Request_GetEventBatch_PB'
module.exports.GetEventBatchResponse = builder.build 'Response_GetEventBatch_PB'
module.exports.RemoveParticipantRequest = builder.build 'Request_RemoveParticipant_PB'
module.exports.RemoveParticipantResponse = builder.build 'Response_RemoveParticipant_PB'
module.exports.EndSessionRequest = builder.build 'Request_EndSession_PB'
module.exports.EndSessionResponse = builder.build 'Response_EndSession_PB'
module.exports.AddToBaseFileRequest = builder.build 'Request_AddToBaseFile_PB'
module.exports.AddToBaseFileResponse = builder.build 'Response_AddToBaseFile_PB'
module.exports.GetFromBaseFileRequest = builder.build 'Request_GetFromBaseFile_PB'
module.exports.GetFromBaseFileResponse = builder.build 'Response_GetFromBaseFile_PB'
module.exports.UpdateNotificationIdRequest = builder.build 'Request_UpdateNotificationID_PB'
module.exports.UpdateNotificationIdResponse = builder.build 'Response_UpdateNotificationID_PB'
module.exports.Event = builder.build 'CollabrifyEvent_PB'
ClientVersion = "3.0.1"
module.exports.ClientVersion = ClientVersion
global.host = '166.collabrify-cloud.appspot.com'

module.exports.chunkSize = 1024*1024*30

module.exports.request = (options) =>
	options.reject ||= ->
	try
		http_options =
			host: global.host
			path: '/request'
			method: 'POST'
			withCredentials: false
		request = http.request(http_options, ->)

		request.xhr.responseType = 'arraybuffer'
		request.xhr.onreadystatechange = ->
			if request.xhr.readyState != 4
				return
			if request.xhr.status == 200
				if buf = ByteBuffer.wrap(request.xhr.response)#, 'base64')
					header = ResponseHeader.decodeDelimited(buf)
					if header.success_flag
						try
							options.ondone(buf, header)
							return
						catch e
							options.reject e
					else
						options.reject (new Error(header.exception.exception_type + ': ' + header.exception.message))
			else
				options.reject new Error('Server not accessable')

		request.xhr.ontimeout = ->
			options.reject new Error('timeout')

		requestHeader = new RequestHeader
			request_type: RequestType[options.header]
			include_timestamp_in_response: options.include_timestamp_in_response
			#client_version: ClientVersion
		
		request.write requestHeader.encodeDelimited().toBuffer()
		request.write options.body.encodeDelimited().toBuffer()
		request.write(options.message) if options.message?
		request.on 'error', (e) ->
			options.reject e	
		request.end()
	catch e
		options.reject e

requestQueue = []

requestSynch = (options) ->
	ondone = options.ondone
	reject = options.reject
	options.ondone = (buf) ->
		requestQueue.shift()
		module.exports.request(requestQueue[0]) if requestQueue[0]
		ondone(buf)

	options.reject = (e) =>
		for event in requestQueue
			event.resend = =>
				module.exports.requestSynch(options)
		reject requestQueue
		requestQueue = []

	unless requestQueue[0]
		module.exports.request(options)
	requestQueue.push options


ByteBuffer::toJSON = ->
	JSON.parse(this.readUTF8StringBytes(this.remaining()))

module.exports.ByteBuffer = ByteBuffer

module.exports.requestSynch = requestSynch

