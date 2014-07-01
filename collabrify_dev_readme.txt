setup
insall node.js
npm insall coffee-script
npm install mocha
npm install chai
npm install -g browserify

run tests:
mocha --compilers coffee:coffee-script/register -R spec

Compile
browserify -t coffeeify --extension=".coffee" main.js -o ./release/collabrify.js
browserify -t coffeeify --extension=".coffee" test/tests.js -o tests_bundle.js

Names should be camelCase unless they are events or file_names which are snake_case or callbacks which are everythingtogether or variables that directly map to things in .proto files in which case they should be named accordingly.

header => Collabrifyheader
body => CollabrifyResponse
use httpHeader and httpBody otherwise

The compiler is not your friend (because it doesnt exist, dont try to write java code in js).
If you do not follow documentation, unexpected behavior will occur, this is normal.

Important Files:

collabrify-x.x.x.js: Final Deploy script
main.js: script that makes public CollabrifyClient. This is compiled by browserify to produce bundle.js
collabrify.coffee: cofiguration, defination of "Collabrify" pseudo-class, helpers
collabrify_client.coffee: CollabrifyClient
test.html: runs tests if opened in a browser
tests_bundle.js: compiled tests script


Appengine deployment
deploy release/collabrify.js to appengine with path collabrify-client-js.appspot.com/static/collabrify.js
deploy protobufs to appengine with path collabrify-client-js.appspot.com/static/proto/
Make sure to use the right protobuf location in collabrify.coffee

ios protopyting:
$web.loadRequest(NSURLRequest.alloc.initWithURL(NSURL.URLWithString('http://0.0.0.0:8000/index.html')))
c = $web.valueForKeyPath "documentView.webView.mainFrame.javaScriptContext"
cb = c['new_collabrify_client'].callWithArguments [{application_id:'4891981239025664', user_id: 'collabrify.tester@gmail.com'}]
cb.invokeMethod 'createSession', withArguments: [{name: 'asdasdpizza_demo',password: 'password',tags: ['tag899']}]
