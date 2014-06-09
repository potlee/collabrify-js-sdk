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

Create a new client using:

```javascript
	var client = new CollabrifyClient({
		application_id: Long.fromString('1234567890'),
		user_id: 'example@gmail.com'
	});
```

CollabrifyClient#createSession takes in
```javascript
	client.createSession({
		name: 'name of the session',
		password: 'password',
		tags: ['you_sesson_tag1','you_sesson_tag2']
	});
```

CollabrifyClient#listSession takes in
```javascript
	client.listSession(['an', 'array', 'of', 'tags']);
```
and returns a promise that get resolved when a list of sessions objects is available.

## Events







