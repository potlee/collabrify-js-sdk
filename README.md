## Collabrify Javascript Client

The javascript SDK for the Collabrify.it backend

## Installation and quick start

Making your webapp Collabrified with Collabrify is a breeze.
Just drop this script tag in you html file:
```javascript
	<script scr='path/to/hosted/Collabrify.js'></script>
```
Now you can instantiate a Collbrify Client:
```javascript
	var client = new CollabrifyClient({
		application_id: Long.fromString('1234567890'),
		user_id: 'example@gmail.com'
	});
```
Now start a collabrified session:
```javascript
	var client = new CollabrifyClient({
		application_id: Long.fromString('1234567890'),
		user_id: 'example@gmail.com'
	});
	client.createSession({
		name: 'you_session_name',
		password: 'password',
		tags: ['you_sesson_tag1','you_sesson_tag2']
	});
```
On another webpage, lets search for the session and join in:
```javascript
	client = new CollabrifyClient({
		application_id: Long.fromString('1234567890'),
		user_id: 'example@gmail.com'
	});
	client.listSessions(['you_sesson_tags']);
	.then(function (sessions) {
		client.joinSession({session: sessions[0], password: 'password'});
	});
	.then(function (session) {});
	.catch(function (e) {"catch any errors here"})
```
And, BOOM! you App is now collabrified. Send messages between clients like so:
```javascript
	client.broadcast({some: 'data', any: 'data'})
```
And recieve the data on the other clients
```javascript
	client.on('event', function (event) {
		// USE THE DATA HERE
	});
```

## Full API Documentation

### Initialize

```javascript
	var client = new CollabrifyClient({
		application_id: Long.fromString('1234567890'),
		user_id: 'example@gmail.com'
	});
```

### CollabrifyClient#createSession(Object)
```javascript
	client.createSession({
		name: 'name of the session',
		password: 'password',
		tags: ['you_sesson_tag1','you_sesson_tag2']
	});
```
Returns a promise that get resolved when a sessions is created on server.

### CollabrifyClient#listSession(Array, boolean)
```javascript
	client.listSession(['an', 'array', 'of', 'tags']);
```
Returns a promise that get resolved when a list of session objects is available.

The second (optional, defaults to false) boolean argument determines whether a filter or exact match query is performed (false = filter, true = exact match).
With filter, a session will be included if their tag list contains all of the tags contained in the array.
With exact match, a session will be included if and only if their tag list matches the specified tag list.

Example:
Session 1's tag: ['apple', 'orange', 'banana']
listSession(['apple']) will include Session 1.
listSession(['apple'], true) will not include Session 1.

### Collaborify#joinSession(Object)
```javascript
	client.joinSession({session: session, password: 'password'});
```
Returns a promise that gets resolved when the session is joined.

### CollabrifyClient#broadbast()
```javascript
	client.broadcast({any: 'javascript', object: 1});
```
Returns a promise that gets resolved when broadcast is done. If a ArrayBuffer object is passed, it is passed along as raw data.

### CollabrifyClient#leaveSession()
```javascript
	client.leaveSession();
```
Returns a promise that gets resolved when session has been left.

### CollabrifyClient#endSession()
```javascript
	client.endSession();
```
Returns a promise that gets resolved when session has been left. Can only be called by owner.

### CollabrifyClient#preventFurtherJoins()
```javascript
	client.preventFurtherJoins();
```
Returns a promise that gets resolved when a confirmation from the server is recieved. Can only be called by owner.

### CollabrifyClient#pauseEvents()
```javascript
	client.pauseEvents();
```
Pauses incoming events.

### CollabrifyClient#resumeEvents()
```javascript
	client.resumeEvents();
```
Resumes incoming events.

## Events

### event(event)
#### event#data()
Returns JSON parsed data
### event#rawData()
Returns raw bytes
### user_joined(user)
### user_left(user)
### sesson_ended
### notifications_start
### notifications_error
### notifications_close

## Properties

#### CollabrifyClient#session
This object contains information about the active session. undefined otherwise.

#### CollabrifyClient#participant
This object contains information about the current user if a session is active. undefined otherwise.

#### CollabrifyClient#submission_registration_id
The current submission_registration_id.

## Errors
All errors except for notification errors are handled through promises.
When a broadcast call fails, the catch handler passes an Array of events (that failed) that have a resend() method that can be used to try to send the event again.

## Compatibility

Should work on
#### Android >= 4.0
#### iOS safari >= 6.0
#### IE 11 (Desktop and Windows Phone)
#### Chrome >= 7
#### Opera 11.6

Use of a Promise pollyfill is recommended. Take a look at https://github.com/then/promise 