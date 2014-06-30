call browserify -t coffeeify --extension=".coffee" main.js -o ./release/collabrify.js
call browserify -t coffeeify --extension=".coffee" test/tests.js -o test/tests_bundle.js