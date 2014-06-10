ByteBuffer = require 'bytebuffer'
ProtoBuf = require "./ProtoBuf.js/ProtoBuf.js"
http = require 'http'
builder = ProtoBuf.loadProtoFile("protocol-buffers/proto/Collabrify-v2/CollabrifyProtocolBuffer.proto")
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
module.exports.Notification_RemoveParticipant = builder.build 'Notification_RemoveParticipantB'
module.exports.Notification_OnChannelConnected = builder.build 'Notification_OnChannelConnected_PB'
module.exports.NotificationMessageType = builder.build 'NotificationMessageType_PB'
module.exports.AddParticipantRequest = builder.build 'Request_AddParticipant_PB'
module.exports.AddParticipantResponse = builder.build 'Response_AddParticipant_PB'
module.exports.GetParticipantRequest = builder.build 'Request_GetParticipant_PB'
module.exports.GetParticipantResponse = builder.build 'Response_GetParticipant_PB'
module.exports.GetEventRequest = builder.build 'Request_GetEvent_PB'
module.exports.GetEventResponse = builder.build 'Response_GetEvent_PB'
module.exports.RemoveParticipantRequest = builder.build 'Request_RemoveParticipant_PB'
module.exports.RemoveParticipantResponse = builder.build 'Response_RemoveParticipant_PB'
module.exports.EndSessionRequest = builder.build 'Request_EndSession_PB'
module.exports.EndSessionResponse = builder.build 'Response_EndSession_PB'
module.exports.AddToBaseFileRequest = builder.build 'Request_AddToBaseFile_PB'
module.exports.AddToBaseFileResponse = builder.build 'Response_AddToBaseFile_PB'
module.exports.GetFromBaseFileRequest = builder.build 'Request_GetFromBaseFile_PB'
module.exports.GetFromBaseFileResponse = builder.build 'Response_GetFromBaseFile_PB'
global.host = '166.collabrify-cloud.appspot.com'
#global.host =  'localhost:9292'

module.exports.chunkSize = 1024*1024*5

module.exports.request = (options) =>
	options.reject ||= ->
	client = @client
	callback = (res) ->
		res.setEncoding('base64') if res.setEncoding
		res.on 'data', (chunk) ->
			buf = ByteBuffer.wrap(chunk)#, 'base64')
			header = ResponseHeader.decodeDelimited(buf)
			if header.success_flag
				options.ondone(buf, header)
			else
				options.reject (new Error(header.exception.exception_type + ': ' + header.exception.message))

		res.on 'error', (e) ->
			options.reject e
	
	http_options =
		host: global.host
		path: '/request'
		method: 'POST'
		withCredentials: false
	request = http.request(http_options, callback)

	request.xhr.responseType = 'arraybuffer' if request.xhr
	request.write (new RequestHeader
		request_type: RequestType[options.header]
		include_timestamp_in_response: options.include_timestamp_in_response
	).encodeDelimited().toBuffer()
	request.write options.body.encodeDelimited().toBuffer()
	request.write(options.message) if options.message?
	request.on 'error', (e) =>
		alert 'this shoud happen'
	request.end()

requestQueue = []

requestSynch = (options) =>
	ondone = options.ondone
	options.ondone = (buf) ->
		ondone(buf)
		requestQueue.shift()
		module.exports.request(requestQueue[0]) if requestQueue[0]

	if !requestQueue[0]
		module.exports.request(options)
	requestQueue.push options

	
module.exports.requestSynch = requestSynch

