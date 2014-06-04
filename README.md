## Collabrify Javascript Client

The javascript SDK for the Collabrify.it backend

## Installation

Making your webapp Collabrified with Collabrify is a breeze.
Just drop this script tag in you html file:
```javascript
	<script scr='path/to/hosted/Collabrify.js'></script>
```
Now you can initiatiate a Collbrify Client:
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
		name: 'you_session_name'
		password: 'password'
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
	client.ondone('list_sessions', function (sessions) {
		client.joinSession(sessions[0])
	}
	client.ondone('join_sesion', function (session) {});
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
