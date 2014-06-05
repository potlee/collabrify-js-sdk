setup
insall node.js
npm install bytebuffer.js
npm insall -g coffeescript
npm install -g mocha
npm install -g chai
npm install browserify

run tests:
mocha --compilers coffee:coffee-script/register -R spec

Compile
browserify -t coffeeify --extension=".coffee" main.js -o bundle.js
browserify -t coffeeify --extension=".coffee" test/tests.js -o tests_bundle.js

Names should be camelCase unless they are events or file_names which are snake_case or callbacks which are everythingtogether or variables that directly map to things in .proto files in which case they should be named accordingly.

header => Collabrifyheader
body => CollabrifyResponse
use httpHeader and httpBody otherwise

ios protopyting:
$web.loadRequest(NSURLRequest.alloc.initWithURL(NSURL.URLWithString('http://0.0.0.0:8000/pizza.html')))
c = $web.valueForKeyPath "documentView.webView.mainFrame.javaScriptContext"

The compiler is not your friend (because it doesnt exist).
If you do not follow documentation, unexpected behavior will occur, this is normal.

Files:

bundle.js: Final Deploy script
main.js: script that makes plublic CollabrifyClient. This is compiled by browserify to produce bundle.js
collabrify.coffee: cofiguration, defination of "Collabrify" pseudo-class, helpers
collabrify_client.coffee: CollabrifyClient
test.html: runs tests if opened in a browser
tests_bundle.js: compiled tests script
