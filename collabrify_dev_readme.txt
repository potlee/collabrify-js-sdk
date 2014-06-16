setup
insall node.js
npm install promise --save
npm install bytebuffer.js
npm insall -g coffeescript
npm install -g mocha
npm install -g chai
npm install browserify
npm install browser-request

run tests:
mocha --compilers coffee:coffee-script/register -R spec

Compile
browserify -t coffeeify --extension=".coffee" main.js -o bundle.js
browserify -t coffeeify --extension=".coffee" test/tests.js -o tests_bundle.js

Names should be camelCase unless they are events or file_names which are snake_case or callbacks which are everythingtogether or variables that directly map to things in .proto files in which case they should be named accordingly.

header => Collabrifyheader
body => CollabrifyResponse
use httpHeader and httpBody otherwise

The compiler is not your friend (because it doesnt exist, dont try to write java code in js).
If you do not follow documentation, unexpected behavior will occur, this is normal.

Important Files:

collabrify-x.x.x.js: Final Deploy script
main.js: script that makes plublic CollabrifyClient. This is compiled by browserify to produce bundle.js
collabrify.coffee: cofiguration, defination of "Collabrify" pseudo-class, helpers
collabrify_client.coffee: CollabrifyClient
test.html: runs tests if opened in a browser
tests_bundle.js: compiled tests script

ios protopyting:
$web.loadRequest(NSURLRequest.alloc.initWithURL(NSURL.URLWithString('http://0.0.0.0:8000/index.html')))
c = $web.valueForKeyPath "documentView.webView.mainFrame.javaScriptContext"
cb = c['new_collabrify_client'].callWithArguments [{application_id:'4891981239025664', user_id: 'collabrify.tester@gmail.com'}]
cb.invokeMethod 'createSession', withArguments: [{name: 'asdasdpizza_demo',password: 'password',tags: ['tag899']}]
