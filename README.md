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
	client.on('event', function (data) {
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

### CollabrifyClient#listSession(Array)
```javascript
	client.listSession(['an', 'array', 'of', 'tags']);
```
Returns a promise that get resolved when a list of sessions objects is available.

### Collaborify#joinSession(Object)
```javascript
	client.joinSession({session: session, password: 'password'});
```
Returns a promise that gets resolved when the session is joined.

### CollabrifyClient#broadbast()
```javascript
	client.broadcast({any: 'javascript', object: 1});
```
Returns a promise that gets resolved when broadcast is done.

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

#### event
#### user_joined(user)
#### user_left(user)
#### sesson_ended
#### notifications_start
#### notifications_error
#### notifications_close

## Properties

#### CollabrifyClient#session
This object contains information about the active session. undefined otherwise.

#### CollabrifyClient#participant
This object contains information about the current user if a session is active. undefined otherwise.

#### CollabrifyClient#submission_registration_id
The current submission_registration_id.

## Errors
All errors except for notification errors are handled through promises.




