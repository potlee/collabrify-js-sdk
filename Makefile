test:
	browserify -t coffeeify --extension=".coffee" main.js -o ./release/collabrify.js;mocha --compilers coffee:coffee-script/register -R spec
compile:
	browserify -t coffeeify --extension=".coffee" test/tests.js -o tests_bundle.js
