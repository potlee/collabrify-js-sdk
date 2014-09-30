require './chai'
ProtoBuf = require "../ProtoBuf.js"
CollabrifyClient = require '../collabrify_client'
EventEmitter = require('../ordered_event_emitter');
builder = ProtoBuf.loadProtoFile "../proto/CollabrifyProtocolBuffer.proto"
CollabrifyNotification = builder.build 'CollabrifyNotification_PB'
Notification_AddParticipant = builder.build 'Notification_AddParticipant_PB'
Notification_RemoveParticipant = builder.build 'Notification_RemoveParticipant_PB'
Participant = builder.build 'Participant_PB'

describe 'OrderedEmitter', ->
	it 'should only emit ordered event once per order id', (done) ->
		emitter = new EventEmitter()
		counts = []
		emitter.on 'event', (e) ->
			console.log(e)
			if counts[e.order_id.low]
				done(e.order_id.low + 'repeated')
			counts[e.order_id.low] = true
			if counts[3]
				done()
		emitter.emitOrdered 'event', {order_id: {low: 0}}
		emitter.emitOrdered 'event', {order_id: {low: 0}}
		emitter.emitOrdered 'event', {order_id: {low: 0}}
		emitter.emitOrdered 'event', {order_id: {low: 1}}
		emitter.emitOrdered 'event', {order_id: {low: 1}}
		emitter.emitOrdered 'event', {order_id: {low: 3}}
		emitter.emitOrdered 'event', {order_id: {low: 3}}
		emitter.emitOrdered 'event', {order_id: {low: 2}}
		
describe 'CollabrifyClient', ->

	beforeEach ->
		@c = new CollabrifyClient
			application_id: '4891981239025664'
			user_id: 'collabrify.tester@gmail.com'

	afterEach (done) ->
	  cleanup = =>
				if(@c.session)
					@c.leaveSession()
				@c = null
				setTimeout done, 500
			setTimeout cleanup, 500
		
	it 'should register and emit events', (done) ->
		@c.on 'custom_event', -> 
			done()
		@c.eventEmitter.emit('custom_event')

	it 'should initialize with properties', ->
		#@c.application_id.should.equal Long.fromString('4891981239025664')
		@c.user_id.should.equal 'collabrify.tester@gmail.com'
	
	it 'should make a succesfull warmup request', (done) ->
		@c.on 'ready', ->
			done()
		@c.on 'error', (error) ->
			done(error)

	it 'should broadcast message', (done) ->
		this.timeout(3000)
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: false
		.catch (error) ->
			done(error)
		@c.on 'notifications_start', =>
			@c.broadcast deep: 'potlee'
			.catch (e) ->
				done(e)
		@c.on 'event', (event) ->
			event.data().deep.should.equal 'potlee'
			done()
		@c.on 'notifications_error', (error) ->
			done(error)

	it 'should manually fetch large events', (done) ->
		this.timeout(15000)
		
		data = [{"removed":[],"addedOrMoved":[{"nodeType":3,"id":46,"textContent":"\n","previousSibling":{"id":4},"parentNode":{"id":3}},{"nodeType":1,"id":47,"tagName":"BODY","attributes":{"class":"cart-page-type index-page","collabrid":"31","id":"ctl00_bodyTag"},"previousSibling":{"id":46},"parentNode":{"id":3}},{"nodeType":3,"id":48,"textContent":"\n","previousSibling":null,"parentNode":{"id":47}},{"nodeType":1,"id":49,"tagName":"FORM","attributes":{"action":"","collabrid":"32","id":"aspnetForm","method":"post","name":"aspnetForm"},"previousSibling":{"id":48},"parentNode":{"id":47}},{"nodeType":3,"id":50,"textContent":"\n","previousSibling":null,"parentNode":{"id":49}},{"nodeType":1,"id":51,"tagName":"INPUT","attributes":{"collabrid":"33","id":"__VIEWSTATE","name":"__VIEWSTATE","type":"hidden","value":"/wEPDwUKLTMxNjc3NTM3NQ9kFgJmD2QWAgIDDxYCHgVjbGFzcwUZY2FydC1wYWdlLXR5cGUgaW5kZXgtcGFnZRYCAgEPZBYCAgcPZBYCAgMPDxYCHgdWaXNpYmxlaGRkGAEFHl9fQ29udHJvbHNSZXF1aXJlUG9zdEJhY2tLZXlfXxYDBRdjdGwwMCRjdGwwMyRjdGwwMSRpbWJHbwUwY3RsMDAkcGFnZUNvbnRlbnQkY3RsMDAkcHJvZHVjdExpc3QkY3RsMDEkaW1iQWRkBTBjdGwwMCRwYWdlQ29udGVudCRjdGwwMCRwcm9kdWN0TGlzdCRjdGwwMiRpbWJBZGQOjbuf+GMZ/0BrrYF36Jklf6Xqow=="},"previousSibling":{"id":50},"parentNode":{"id":49}},{"nodeType":3,"id":52,"textContent":"\n","previousSibling":{"id":51},"parentNode":{"id":49}},{"nodeType":1,"id":53,"tagName":"DIV","attributes":{"collabrid":"34","id":"wrapper"},"previousSibling":{"id":52},"parentNode":{"id":49}},{"nodeType":3,"id":54,"textContent":"\n","previousSibling":null,"parentNode":{"id":53}},{"nodeType":1,"id":55,"tagName":"TABLE","attributes":{"border":"0","cellpadding":"0","cellspacing":"0","class":"page-container","collabrid":"35","id":"ctl00_container"},"previousSibling":{"id":54},"parentNode":{"id":53}},{"nodeType":3,"id":56,"textContent":"\n","previousSibling":null,"parentNode":{"id":55}},{"nodeType":1,"id":57,"tagName":"TBODY","attributes":{},"previousSibling":{"id":56},"parentNode":{"id":55}},{"nodeType":1,"id":58,"tagName":"TR","attributes":{"collabrid":"36","id":"ctl00_header"},"previousSibling":null,"parentNode":{"id":57}},{"nodeType":3,"id":59,"textContent":"\n","previousSibling":null,"parentNode":{"id":58}},{"nodeType":1,"id":60,"tagName":"TD","attributes":{"class":"page-header","collabrid":"37","id":"ctl00_headerContent"},"previousSibling":{"id":59},"parentNode":{"id":58}},{"nodeType":1,"id":61,"tagName":"LINK","attributes":{"collabrid":"38","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/29/fonts.googleapis.com/css?family=PT+Sans:400,700,400italic,700italic","rel":"stylesheet","type":"text/css"},"previousSibling":null,"parentNode":{"id":60}},{"nodeType":3,"id":62,"textContent":"\n","previousSibling":{"id":61},"parentNode":{"id":60}},{"nodeType":1,"id":63,"tagName":"SCRIPT","attributes":{"collabrid":"39"},"previousSibling":{"id":62},"parentNode":{"id":60}},{"nodeType":3,"id":64,"textContent":"\n\nvar fq = location.search.replace(/^.*?\\=/, '');\nif (fq == 1) {\n   document.cookie = \"show_quote_link=yup\";\n}\n\n","previousSibling":null,"parentNode":{"id":63}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":3,"id":65,"textContent":"\n","previousSibling":{"id":63},"parentNode":{"id":60}},{"nodeType":1,"id":66,"tagName":"STYLE","attributes":{"collabrid":"40"},"previousSibling":{"id":65},"parentNode":{"id":60}},{"nodeType":3,"id":67,"textContent":"\n","previousSibling":{"id":66},"parentNode":{"id":60}},{"nodeType":1,"id":68,"tagName":"SCRIPT","attributes":{"collabrid":"41","src":"/40b4bad8cb684f37a2b9e62bb4c495dc/30/www.big-georges.com/preload.js","type":"text/javascript"},"previousSibling":{"id":67},"parentNode":{"id":60}},{"nodeType":3,"id":69,"textContent":"\n&lt;!--\ndiv.breadcrumb { margin: 4px 3px; }\n.category-list tr td { height:80px; vertical-align:middle; }\n--&gt;\n","previousSibling":null,"parentNode":{"id":66}},{"nodeType":3,"id":70,"textContent":"\n        //&lt;![CDATA[\n        \n        //]]&gt;\n        ","previousSibling":null,"parentNode":{"id":68}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":3,"id":71,"textContent":"\n","previousSibling":{"id":68},"parentNode":{"id":60}},{"nodeType":1,"id":72,"tagName":"SCRIPT","attributes":{"collabrid":"42","type":"text/javascript"},"previousSibling":{"id":71},"parentNode":{"id":60}},{"nodeType":3,"id":73,"textContent":"\n\n  var _gaq = _gaq || [];\n  _gaq.push(['_setAccount', 'UA-587067-1']);\n  _gaq.push(['_trackPageview']);\n\n  (function() {\n    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;\n    ga.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'stats.g.doubleclick.net/dc.js';\n    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);\n  })();\n\n","previousSibling":null,"parentNode":{"id":72}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":1,"id":74,"tagName":"SCRIPT","attributes":{"type":"text/javascript","async":"","src":"http://stats.g.doubleclick.net/dc.js"},"previousSibling":{"id":7},"parentNode":{"id":4}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":1,"id":75,"tagName":"TR","attributes":{"class":"page-body","collabrid":"71","id":"ctl00_body"},"previousSibling":{"id":58},"parentNode":{"id":57}},{"nodeType":3,"id":76,"textContent":"\n","previousSibling":{"id":60},"parentNode":{"id":58}},{"nodeType":3,"id":77,"textContent":"\n","previousSibling":{"id":72},"parentNode":{"id":60}},{"nodeType":1,"id":78,"tagName":"DIV","attributes":{"collabrid":"43","id":"topbar_jl"},"previousSibling":{"id":77},"parentNode":{"id":60}},{"nodeType":3,"id":79,"textContent":"\n","previousSibling":{"id":78},"parentNode":{"id":60}},{"nodeType":1,"id":80,"tagName":"DIV","attributes":{"collabrid":"51","id":"main_jl"},"previousSibling":{"id":79},"parentNode":{"id":60}},{"nodeType":1,"id":81,"tagName":"DIV","attributes":{"collabrid":"44","id":"topbar_jl_content"},"previousSibling":null,"parentNode":{"id":78}},{"nodeType":3,"id":82,"textContent":"\n","previousSibling":null,"parentNode":{"id":81}},{"nodeType":1,"id":83,"tagName":"A","attributes":{"class":"reg","collabrid":"45","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/31/www.big-georges.com/index.asp?PageAction=COMPANY"},"previousSibling":{"id":82},"parentNode":{"id":81}},{"nodeType":3,"id":84,"textContent":"\n","previousSibling":{"id":83},"parentNode":{"id":81}},{"nodeType":1,"id":85,"tagName":"A","attributes":{"class":"reg","collabrid":"46","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/32/www.big-georges.com/index.asp?PageAction=CONTACTUS"},"previousSibling":{"id":84},"parentNode":{"id":81}},{"nodeType":3,"id":86,"textContent":"\n","previousSibling":{"id":85},"parentNode":{"id":81}},{"nodeType":1,"id":87,"tagName":"A","attributes":{"class":"reg","collabrid":"47","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/33/www.big-georges.com/index.asp?PageAction=LOGIN"},"previousSibling":{"id":86},"parentNode":{"id":81}},{"nodeType":3,"id":88,"textContent":"\n","previousSibling":{"id":87},"parentNode":{"id":81}},{"nodeType":1,"id":89,"tagName":"A","attributes":{"class":"reg","collabrid":"48","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/34/www.big-georges.com/testimonials.aspx"},"previousSibling":{"id":88},"parentNode":{"id":81}},{"nodeType":3,"id":90,"textContent":"\n","previousSibling":{"id":89},"parentNode":{"id":81}},{"nodeType":1,"id":91,"tagName":"A","attributes":{"class":"reg","collabrid":"49","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/35/www.big-georges.com/index.asp?PageAction=MYACCOUNT"},"previousSibling":{"id":90},"parentNode":{"id":81}},{"nodeType":3,"id":92,"textContent":"\n","previousSibling":{"id":91},"parentNode":{"id":81}},{"nodeType":1,"id":93,"tagName":"A","attributes":{"class":"last","collabrid":"50","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/36/www.big-georges.com/index.asp?PageAction=CHECKOUT"},"previousSibling":{"id":92},"parentNode":{"id":81}},{"nodeType":3,"id":94,"textContent":"\n","previousSibling":{"id":93},"parentNode":{"id":81}},{"nodeType":3,"id":95,"textContent":"About Us","previousSibling":null,"parentNode":{"id":83}},{"nodeType":3,"id":96,"textContent":"Contact Us","previousSibling":null,"parentNode":{"id":85}},{"nodeType":3,"id":97,"textContent":"Login","previousSibling":null,"parentNode":{"id":87}},{"nodeType":3,"id":98,"textContent":"Testimonials","previousSibling":null,"parentNode":{"id":89}},{"nodeType":3,"id":99,"textContent":"My Account","previousSibling":null,"parentNode":{"id":91}},{"nodeType":3,"id":100,"textContent":"Checkout","previousSibling":null,"parentNode":{"id":93}},{"nodeType":3,"id":101,"textContent":"\n","previousSibling":null,"parentNode":{"id":80}},{"nodeType":1,"id":102,"tagName":"DIV","attributes":{"collabrid":"52","id":"header_jl"},"previousSibling":{"id":101},"parentNode":{"id":80}},{"nodeType":3,"id":103,"textContent":"\n","previousSibling":null,"parentNode":{"id":102}},{"nodeType":1,"id":104,"tagName":"DIV","attributes":{"collabrid":"53","id":"header_logo_jl"},"previousSibling":{"id":103},"parentNode":{"id":102}},{"nodeType":3,"id":105,"textContent":"\n","previousSibling":{"id":104},"parentNode":{"id":102}},{"nodeType":1,"id":106,"tagName":"DIV","attributes":{"collabrid":"56","id":"nav_jl"},"previousSibling":{"id":105},"parentNode":{"id":102}},{"nodeType":3,"id":107,"textContent":"\n","previousSibling":{"id":106},"parentNode":{"id":102}},{"nodeType":1,"id":108,"tagName":"DIV","attributes":{"collabrid":"70","style":"clear:both;"},"previousSibling":{"id":107},"parentNode":{"id":102}},{"nodeType":3,"id":109,"textContent":"\n","previousSibling":{"id":108},"parentNode":{"id":102}},{"nodeType":1,"id":110,"tagName":"A","attributes":{"collabrid":"54","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/37/www.big-georges.com/index.asp"},"previousSibling":null,"parentNode":{"id":104}},{"nodeType":1,"id":111,"tagName":"IMG","attributes":{"border":"0","collabrid":"55","height":"90","src":"/40b4bad8cb684f37a2b9e62bb4c495dc/38/www.big-georges.com/themes/migration-1-1/images/header-new.jpg","width":"980"},"previousSibling":null,"parentNode":{"id":110}},{"nodeType":3,"id":112,"textContent":"\n","previousSibling":null,"parentNode":{"id":106}},{"nodeType":1,"id":113,"tagName":"UL","attributes":{"collabrid":"57"},"previousSibling":{"id":112},"parentNode":{"id":106}},{"nodeType":3,"id":114,"textContent":"\n","previousSibling":{"id":113},"parentNode":{"id":106}},{"nodeType":3,"id":115,"textContent":"\n","previousSibling":null,"parentNode":{"id":113}},{"nodeType":1,"id":116,"tagName":"LI","attributes":{"collabrid":"58"},"previousSibling":{"id":115},"parentNode":{"id":113}},{"nodeType":3,"id":117,"textContent":"\n","previousSibling":{"id":116},"parentNode":{"id":113}},{"nodeType":1,"id":118,"tagName":"LI","attributes":{"collabrid":"60"},"previousSibling":{"id":117},"parentNode":{"id":113}},{"nodeType":3,"id":119,"textContent":"\n","previousSibling":{"id":118},"parentNode":{"id":113}},{"nodeType":1,"id":120,"tagName":"LI","attributes":{"collabrid":"62"},"previousSibling":{"id":119},"parentNode":{"id":113}},{"nodeType":3,"id":121,"textContent":"\n","previousSibling":{"id":120},"parentNode":{"id":113}},{"nodeType":1,"id":122,"tagName":"LI","attributes":{"collabrid":"64"},"previousSibling":{"id":121},"parentNode":{"id":113}},{"nodeType":3,"id":123,"textContent":"\n","previousSibling":{"id":122},"parentNode":{"id":113}},{"nodeType":1,"id":124,"tagName":"LI","attributes":{"collabrid":"66"},"previousSibling":{"id":123},"parentNode":{"id":113}},{"nodeType":3,"id":125,"textContent":"\n","previousSibling":{"id":124},"parentNode":{"id":113}},{"nodeType":1,"id":126,"tagName":"LI","attributes":{"collabrid":"68"},"previousSibling":{"id":125},"parentNode":{"id":113}},{"nodeType":3,"id":127,"textContent":"\n","previousSibling":{"id":126},"parentNode":{"id":113}},{"nodeType":1,"id":128,"tagName":"A","attributes":{"collabrid":"59","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/39/www.big-georges.com/appliances.aspx"},"previousSibling":null,"parentNode":{"id":116}},{"nodeType":3,"id":129,"textContent":"APPLIANCES","previousSibling":null,"parentNode":{"id":128}},{"nodeType":1,"id":130,"tagName":"A","attributes":{"collabrid":"61","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/40/www.big-georges.com/tvandvideo.aspx"},"previousSibling":null,"parentNode":{"id":118}},{"nodeType":3,"id":131,"textContent":"TV & HOME THEATER","previousSibling":null,"parentNode":{"id":130}},{"nodeType":1,"id":132,"tagName":"A","attributes":{"collabrid":"63","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/41/www.big-georges.com/fireplaces.aspx"},"previousSibling":null,"parentNode":{"id":120}},{"nodeType":3,"id":133,"textContent":"FIREPLACES","previousSibling":null,"parentNode":{"id":132}},{"nodeType":1,"id":134,"tagName":"A","attributes":{"collabrid":"65","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/42/www.big-georges.com/outdoor-grill.aspx"},"previousSibling":null,"parentNode":{"id":122}},{"nodeType":3,"id":135,"textContent":"OUTDOOR GRILLS","previousSibling":null,"parentNode":{"id":134}},{"nodeType":1,"id":136,"tagName":"A","attributes":{"collabrid":"67","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/43/www.big-georges.com/Mattresses.aspx"},"previousSibling":null,"parentNode":{"id":124}},{"nodeType":3,"id":137,"textContent":"MATTRESSES","previousSibling":null,"parentNode":{"id":136}},{"nodeType":1,"id":138,"tagName":"A","attributes":{"collabrid":"69","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/44/www.big-georges.com/furniture.aspx"},"previousSibling":null,"parentNode":{"id":126}},{"nodeType":3,"id":139,"textContent":"FURNITURE","previousSibling":null,"parentNode":{"id":138}},{"nodeType":3,"id":140,"textContent":"\n","previousSibling":null,"parentNode":{"id":75}},{"nodeType":1,"id":141,"tagName":"TD","attributes":{"class":"page-body-content","collabrid":"72","id":"ctl00_bodyContent"},"previousSibling":{"id":140},"parentNode":{"id":75}},{"nodeType":1,"id":142,"tagName":"TABLE","attributes":{"border":"0","cellpadding":"0","cellspacing":"0","class":"page-body-columns","collabrid":"73","id":"ctl00_columns"},"previousSibling":null,"parentNode":{"id":141}},{"nodeType":3,"id":143,"textContent":"\n","previousSibling":null,"parentNode":{"id":142}},{"nodeType":1,"id":144,"tagName":"TBODY","attributes":{},"previousSibling":{"id":143},"parentNode":{"id":142}},{"nodeType":1,"id":145,"tagName":"TR","attributes":{"collabrid":"74"},"previousSibling":null,"parentNode":{"id":144}},{"nodeType":3,"id":146,"textContent":"\n","previousSibling":null,"parentNode":{"id":145}},{"nodeType":1,"id":147,"tagName":"TD","attributes":{"class":"page-column-left","collabrid":"75","id":"ctl00_leftColumn"},"previousSibling":{"id":146},"parentNode":{"id":145}},{"nodeType":1,"id":148,"tagName":"TD","attributes":{"class":"page-column-center","collabrid":"133","id":"ctl00_centerColumn"},"previousSibling":{"id":147},"parentNode":{"id":145}},{"nodeType":1,"id":149,"tagName":"DIV","attributes":{"collabrid":"76","id":"leftcolumn_wrapper"},"previousSibling":null,"parentNode":{"id":147}},{"nodeType":3,"id":150,"textContent":"\n","previousSibling":{"id":149},"parentNode":{"id":147}},{"nodeType":3,"id":151,"textContent":"\n","previousSibling":null,"parentNode":{"id":149}},{"nodeType":1,"id":152,"tagName":"H3","attributes":{"collabrid":"77"},"previousSibling":{"id":151},"parentNode":{"id":149}},{"nodeType":3,"id":153,"textContent":"\n","previousSibling":{"id":152},"parentNode":{"id":149}},{"nodeType":1,"id":154,"tagName":"DIV","attributes":{"collabrid":"78","id":"searchBox","style":"width:120px!important;"},"previousSibling":{"id":153},"parentNode":{"id":149}},{"nodeType":3,"id":155,"textContent":"\n","previousSibling":{"id":154},"parentNode":{"id":149}},{"nodeType":1,"id":156,"tagName":"BR","attributes":{"collabrid":"99"},"previousSibling":{"id":155},"parentNode":{"id":149}},{"nodeType":3,"id":157,"textContent":"\n","previousSibling":{"id":156},"parentNode":{"id":149}},{"nodeType":1,"id":158,"tagName":"H3","attributes":{"collabrid":"100"},"previousSibling":{"id":157},"parentNode":{"id":149}},{"nodeType":3,"id":159,"textContent":"\n","previousSibling":{"id":158},"parentNode":{"id":149}},{"nodeType":1,"id":160,"tagName":"UL","attributes":{"class":"module-list cat-nav","collabrid":"101"},"previousSibling":{"id":159},"parentNode":{"id":149}},{"nodeType":3,"id":161,"textContent":"\n","previousSibling":{"id":160},"parentNode":{"id":149}},{"nodeType":1,"id":162,"tagName":"BR","attributes":{"collabrid":"122"},"previousSibling":{"id":161},"parentNode":{"id":149}},{"nodeType":1,"id":163,"tagName":"BR","attributes":{"collabrid":"123"},"previousSibling":{"id":162},"parentNode":{"id":149}},{"nodeType":3,"id":164,"textContent":"\n","previousSibling":{"id":163},"parentNode":{"id":149}},{"nodeType":1,"id":165,"tagName":"H3","attributes":{"collabrid":"124"},"previousSibling":{"id":164},"parentNode":{"id":149}},{"nodeType":3,"id":166,"textContent":"\n","previousSibling":{"id":165},"parentNode":{"id":149}},{"nodeType":1,"id":167,"tagName":"A","attributes":{"collabrid":"125","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/56/www.facebook.com/pages/Ann-Arbor-MI/Big-Georges-Home-Appliance-Mart/64363012085","target":"_blank"},"previousSibling":{"id":166},"parentNode":{"id":149}},{"nodeType":3,"id":168,"textContent":"\n","previousSibling":{"id":167},"parentNode":{"id":149}},{"nodeType":1,"id":169,"tagName":"A","attributes":{"collabrid":"127","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/58/twitter.com/big_georges","target":"_blank"},"previousSibling":{"id":168},"parentNode":{"id":149}},{"nodeType":3,"id":170,"textContent":"\n","previousSibling":{"id":169},"parentNode":{"id":149}},{"nodeType":1,"id":171,"tagName":"BR","attributes":{"collabrid":"129"},"previousSibling":{"id":170},"parentNode":{"id":149}},{"nodeType":1,"id":172,"tagName":"BR","attributes":{"collabrid":"130"},"previousSibling":{"id":171},"parentNode":{"id":149}},{"nodeType":1,"id":173,"tagName":"BR","attributes":{"collabrid":"131"},"previousSibling":{"id":172},"parentNode":{"id":149}},{"nodeType":1,"id":174,"tagName":"BR","attributes":{"collabrid":"132"},"previousSibling":{"id":173},"parentNode":{"id":149}},{"nodeType":3,"id":175,"textContent":"\n","previousSibling":{"id":174},"parentNode":{"id":149}},{"nodeType":3,"id":176,"textContent":"SEARCH","previousSibling":null,"parentNode":{"id":152}},{"nodeType":3,"id":177,"textContent":"\n","previousSibling":null,"parentNode":{"id":154}},{"nodeType":1,"id":178,"tagName":"TABLE","attributes":{"border":"0","cellpadding":"0","cellspacing":"0","class":"mod-body ","collabrid":"79","width":"100%"},"previousSibling":{"id":177},"parentNode":{"id":154}},{"nodeType":3,"id":179,"textContent":"\n","previousSibling":{"id":178},"parentNode":{"id":154}},{"nodeType":3,"id":180,"textContent":"\n","previousSibling":null,"parentNode":{"id":178}},{"nodeType":1,"id":181,"tagName":"TBODY","attributes":{},"previousSibling":{"id":180},"parentNode":{"id":178}},{"nodeType":1,"id":182,"tagName":"TR","attributes":{"collabrid":"80"},"previousSibling":null,"parentNode":{"id":181}},{"nodeType":1,"id":183,"tagName":"TR","attributes":{"collabrid":"84"},"previousSibling":{"id":182},"parentNode":{"id":181}},{"nodeType":1,"id":184,"tagName":"TR","attributes":{"collabrid":"95"},"previousSibling":{"id":183},"parentNode":{"id":181}},{"nodeType":3,"id":185,"textContent":"\n","previousSibling":{"id":184},"parentNode":{"id":181}},{"nodeType":3,"id":186,"textContent":"\n","previousSibling":null,"parentNode":{"id":182}},{"nodeType":1,"id":187,"tagName":"TD","attributes":{"class":"mod-body-tl","collabrid":"81"},"previousSibling":{"id":186},"parentNode":{"id":182}},{"nodeType":1,"id":188,"tagName":"TD","attributes":{"class":"mod-body-tp","collabrid":"82"},"previousSibling":{"id":187},"parentNode":{"id":182}},{"nodeType":1,"id":189,"tagName":"TD","attributes":{"class":"mod-body-tr","collabrid":"83"},"previousSibling":{"id":188},"parentNode":{"id":182}},{"nodeType":3,"id":190,"textContent":"\n","previousSibling":{"id":189},"parentNode":{"id":182}},{"nodeType":3,"id":191,"textContent":"\n","previousSibling":null,"parentNode":{"id":183}},{"nodeType":1,"id":192,"tagName":"TD","attributes":{"class":"mod-body-lt","collabrid":"85"},"previousSibling":{"id":191},"parentNode":{"id":183}},{"nodeType":1,"id":193,"tagName":"TD","attributes":{"class":"mod-body-body","collabrid":"86"},"previousSibling":{"id":192},"parentNode":{"id":183}},{"nodeType":1,"id":194,"tagName":"TD","attributes":{"class":"mod-body-rt","collabrid":"94"},"previousSibling":{"id":193},"parentNode":{"id":183}},{"nodeType":3,"id":195,"textContent":"\n","previousSibling":{"id":194},"parentNode":{"id":183}},{"nodeType":3,"id":196,"textContent":"\n","previousSibling":null,"parentNode":{"id":193}},{"nodeType":1,"id":197,"tagName":"DIV","attributes":{"collabrid":"87","id":"ctl00_ctl03_ctl01_pnlSearch"},"previousSibling":{"id":196},"parentNode":{"id":193}},{"nodeType":3,"id":198,"textContent":"\n","previousSibling":{"id":197},"parentNode":{"id":193}},{"nodeType":3,"id":199,"textContent":"\n","previousSibling":null,"parentNode":{"id":197}},{"nodeType":1,"id":200,"tagName":"TABLE","attributes":{"cellpadding":"0","cellspacing":"0","collabrid":"88","style":"margin: 0; padding: 0; border: none; border-collapse: collapse;"},"previousSibling":{"id":199},"parentNode":{"id":197}},{"nodeType":3,"id":201,"textContent":"\n","previousSibling":{"id":200},"parentNode":{"id":197}},{"nodeType":3,"id":202,"textContent":"\n","previousSibling":null,"parentNode":{"id":200}},{"nodeType":1,"id":203,"tagName":"TBODY","attributes":{},"previousSibling":{"id":202},"parentNode":{"id":200}},{"nodeType":1,"id":204,"tagName":"TR","attributes":{"collabrid":"89"},"previousSibling":null,"parentNode":{"id":203}},{"nodeType":3,"id":205,"textContent":"\n","previousSibling":{"id":204},"parentNode":{"id":203}},{"nodeType":3,"id":206,"textContent":"\n","previousSibling":null,"parentNode":{"id":204}},{"nodeType":1,"id":207,"tagName":"TD","attributes":{"collabrid":"90","style":"padding-right: 7px; width: 100%"},"previousSibling":{"id":206},"parentNode":{"id":204}},{"nodeType":3,"id":208,"textContent":"\n","previousSibling":{"id":207},"parentNode":{"id":204}},{"nodeType":1,"id":209,"tagName":"TD","attributes":{"collabrid":"92","style":"text-align: right;"},"previousSibling":{"id":208},"parentNode":{"id":204}},{"nodeType":3,"id":210,"textContent":"\n","previousSibling":{"id":209},"parentNode":{"id":204}},{"nodeType":3,"id":211,"textContent":"\n","previousSibling":null,"parentNode":{"id":207}},{"nodeType":1,"id":212,"tagName":"INPUT","attributes":{"class":"textbox search-module-text","collabrid":"91","id":"ctl00_ctl03_ctl01_txtSearch","maxlength":"100","name":"ctl00$ctl03$ctl01$txtSearch","type":"text"},"previousSibling":{"id":211},"parentNode":{"id":207}},{"nodeType":3,"id":213,"textContent":"\n","previousSibling":{"id":212},"parentNode":{"id":207}},{"nodeType":3,"id":214,"textContent":"\n","previousSibling":null,"parentNode":{"id":209}},{"nodeType":1,"id":215,"tagName":"INPUT","attributes":{"alt":"Go","border":"0","collabrid":"93","id":"ctl00_ctl03_ctl01_imbGo","name":"ctl00$ctl03$ctl01$imbGo","src":"/40b4bad8cb684f37a2b9e62bb4c495dc/45/www.big-georges.com/themes/migration-1-1/images/buttons/mod_btn_go.gif","type":"image"},"previousSibling":{"id":214},"parentNode":{"id":209}},{"nodeType":3,"id":216,"textContent":"\n","previousSibling":{"id":215},"parentNode":{"id":209}},{"nodeType":3,"id":217,"textContent":"\n","previousSibling":null,"parentNode":{"id":184}},{"nodeType":1,"id":218,"tagName":"TD","attributes":{"class":"mod-body-bl","collabrid":"96"},"previousSibling":{"id":217},"parentNode":{"id":184}},{"nodeType":1,"id":219,"tagName":"TD","attributes":{"class":"mod-body-bt","collabrid":"97"},"previousSibling":{"id":218},"parentNode":{"id":184}},{"nodeType":1,"id":220,"tagName":"TD","attributes":{"class":"mod-body-br","collabrid":"98"},"previousSibling":{"id":219},"parentNode":{"id":184}},{"nodeType":3,"id":221,"textContent":"\n","previousSibling":{"id":220},"parentNode":{"id":184}},{"nodeType":3,"id":222,"textContent":"OUR PRODUCTS","previousSibling":null,"parentNode":{"id":158}},{"nodeType":3,"id":223,"textContent":"\n","previousSibling":null,"parentNode":{"id":160}},{"nodeType":1,"id":224,"tagName":"LI","attributes":{"collabrid":"102"},"previousSibling":{"id":223},"parentNode":{"id":160}},{"nodeType":1,"id":225,"tagName":"LI","attributes":{"collabrid":"104"},"previousSibling":{"id":224},"parentNode":{"id":160}},{"nodeType":1,"id":226,"tagName":"LI","attributes":{"collabrid":"106"},"previousSibling":{"id":225},"parentNode":{"id":160}},{"nodeType":1,"id":227,"tagName":"LI","attributes":{"collabrid":"108"},"previousSibling":{"id":226},"parentNode":{"id":160}},{"nodeType":1,"id":228,"tagName":"LI","attributes":{"collabrid":"110"},"previousSibling":{"id":227},"parentNode":{"id":160}},{"nodeType":1,"id":229,"tagName":"LI","attributes":{"collabrid":"112"},"previousSibling":{"id":228},"parentNode":{"id":160}},{"nodeType":1,"id":230,"tagName":"LI","attributes":{"collabrid":"114"},"previousSibling":{"id":229},"parentNode":{"id":160}},{"nodeType":1,"id":231,"tagName":"LI","attributes":{"collabrid":"116"},"previousSibling":{"id":230},"parentNode":{"id":160}},{"nodeType":1,"id":232,"tagName":"LI","attributes":{"collabrid":"118"},"previousSibling":{"id":231},"parentNode":{"id":160}},{"nodeType":1,"id":233,"tagName":"LI","attributes":{"collabrid":"120"},"previousSibling":{"id":232},"parentNode":{"id":160}},{"nodeType":3,"id":234,"textContent":"\n","previousSibling":{"id":233},"parentNode":{"id":160}},{"nodeType":1,"id":235,"tagName":"A","attributes":{"collabrid":"103","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/46/www.big-georges.com/shop-by-brand.aspx"},"previousSibling":null,"parentNode":{"id":224}},{"nodeType":3,"id":236,"textContent":"Shop By Brand","previousSibling":null,"parentNode":{"id":235}},{"nodeType":1,"id":237,"tagName":"A","attributes":{"collabrid":"105","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/47/www.big-georges.com/appliances.aspx"},"previousSibling":null,"parentNode":{"id":225}},{"nodeType":3,"id":238,"textContent":"Appliances","previousSibling":null,"parentNode":{"id":237}},{"nodeType":1,"id":239,"tagName":"A","attributes":{"collabrid":"107","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/48/www.big-georges.com/tvandvideo.aspx"},"previousSibling":null,"parentNode":{"id":226}},{"nodeType":3,"id":240,"textContent":"TV & Home Theater","previousSibling":null,"parentNode":{"id":239}},{"nodeType":1,"id":241,"tagName":"A","attributes":{"collabrid":"109","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/49/www.big-georges.com/fireplaces.aspx"},"previousSibling":null,"parentNode":{"id":227}},{"nodeType":3,"id":242,"textContent":"Fireplaces","previousSibling":null,"parentNode":{"id":241}},{"nodeType":1,"id":243,"tagName":"A","attributes":{"collabrid":"111","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/50/www.big-georges.com/outdoor-grill.aspx"},"previousSibling":null,"parentNode":{"id":228}},{"nodeType":3,"id":244,"textContent":"Outdoor Grills","previousSibling":null,"parentNode":{"id":243}},{"nodeType":1,"id":245,"tagName":"A","attributes":{"collabrid":"113","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/51/www.big-georges.com/Mattresses.aspx"},"previousSibling":null,"parentNode":{"id":229}},{"nodeType":3,"id":246,"textContent":"Mattresses","previousSibling":null,"parentNode":{"id":245}},{"nodeType":1,"id":247,"tagName":"A","attributes":{"collabrid":"115","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/52/www.big-georges.com/furniture.aspx"},"previousSibling":null,"parentNode":{"id":230}},{"nodeType":3,"id":248,"textContent":"Furniture","previousSibling":null,"parentNode":{"id":247}},{"nodeType":1,"id":249,"tagName":"A","attributes":{"collabrid":"117","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/53/www.big-georges.com/clearancespecials_1.aspx"},"previousSibling":null,"parentNode":{"id":231}},{"nodeType":3,"id":250,"textContent":"Clearance Specials","previousSibling":null,"parentNode":{"id":249}},{"nodeType":1,"id":251,"tagName":"A","attributes":{"collabrid":"119","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/54/www.big-georges.com/Manufacturer-Rebates.aspx"},"previousSibling":null,"parentNode":{"id":232}},{"nodeType":3,"id":252,"textContent":"Rebates","previousSibling":null,"parentNode":{"id":251}},{"nodeType":1,"id":253,"tagName":"A","attributes":{"collabrid":"121","href":"/40b4bad8cb684f37a2b9e62bb4c495dc/55/www.big-georges.com/appliance-service-installation.aspx"},"previousSibling":null,"parentNode":{"id":233}},{"nodeType":3,"id":254,"textContent":"Service & Installation","previousSibling":null,"parentNode":{"id":253}},{"nodeType":3,"id":255,"textContent":"FOLLOW US ON...","previousSibling":null,"parentNode":{"id":165}},{"nodeType":3,"id":256,"textContent":"\n","previousSibling":null,"parentNode":{"id":167}},{"nodeType":1,"id":257,"tagName":"IMG","attributes":{"alt":"Facebook","collabrid":"126","src":"/40b4bad8cb684f37a2b9e62bb4c495dc/57/www.big-georges.com/themes/migration-1-1/images/facebook.png"},"previousSibling":{"id":256},"parentNode":{"id":167}},{"nodeType":3,"id":258,"textContent":"\n","previousSibling":null,"parentNode":{"id":169}},{"nodeType":1,"id":259,"tagName":"IMG","attributes":{"alt":"Twitter","collabrid":"128","src":"/40b4bad8cb684f37a2b9e62bb4c495dc/59/www.big-georges.com/themes/migration-1-1/images/twitter.png","style":"margin-left: 10px;"},"previousSibling":{"id":258},"parentNode":{"id":169}},{"nodeType":1,"id":260,"tagName":"SCRIPT","attributes":{"collabrid":"134","type":"text/javascript"},"previousSibling":null,"parentNode":{"id":148}},{"nodeType":3,"id":261,"textContent":"\nsetTimeout(function(){var a=document.createElement(\"script\");\nvar b=document.getElementsByTagName(\"script\")[0];\na.src=document.location.protocol+\"//dnn506yrbagrg.cloudfront.net/pages/scripts/0018/5013.js?\"+Math.floor(new Date().getTime()/3600000);\na.async=true;a.type=\"text/javascript\";b.parentNode.insertBefore(a,b)}, 1);\n","previousSibling":null,"parentNode":{"id":260}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":3,"id":262,"textContent":"\n","previousSibling":{"id":260},"parentNode":{"id":148}},{"nodeType":8,"id":263,"textContent":" OwnerIQ Retargeting tag ","previousSibling":{"id":262},"parentNode":{"id":148}},{"nodeType":3,"id":264,"textContent":"\n","previousSibling":{"id":263},"parentNode":{"id":148}},{"nodeType":1,"id":265,"tagName":"SCRIPT","attributes":{"collabrid":"135","type":"text/javascript"},"previousSibling":{"id":264},"parentNode":{"id":148}},{"nodeType":3,"id":266,"textContent":"\n  var _oiqq = _oiqq || [];\n  _oiqq.push(['oiq_doTag']);\n\n  (function() {\n    var oiq = document.createElement('script'); oiq.type = 'text/javascript'; oiq.async = true;\n    oiq.src = document.location.protocol + '//px.owneriq.net/stas/s/cx9r07.js';\n    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(oiq, s);\n  })();\n","previousSibling":null,"parentNode":{"id":265}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":1,"id":267,"tagName":"SCRIPT","attributes":{"type":"text/javascript","async":"","src":"http://px.owneriq.net/stas/s/cx9r07.js"},"previousSibling":{"id":7},"parentNode":{"id":4}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":3,"id":268,"textContent":"\n","previousSibling":{"id":265},"parentNode":{"id":148}},{"nodeType":8,"id":269,"textContent":" End OwnerIQ tag ","previousSibling":{"id":268},"parentNode":{"id":148}},{"nodeType":3,"id":270,"textContent":"\n","previousSibling":{"id":269},"parentNode":{"id":148}},{"nodeType":1,"id":271,"tagName":"SCRIPT","attributes":{"collabrid":"136","src":"/40b4bad8cb684f37a2b9e62bb4c495dc/60/www.big-georges.com/themes/migration-1-1/js/jquery-1.7.2.min.js"},"previousSibling":{"id":270},"parentNode":{"id":148}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":1,"id":272,"tagName":"SCRIPT","attributes":{"src":"http://dnn506yrbagrg.cloudfront.net/pages/scripts/0018/5013.js?391719","async":"","type":"text/javascript"},"previousSibling":{"id":7},"parentNode":{"id":4}}],"attributes":[],"text":[]},{"removed":[],"addedOrMoved":[{"nodeType":1,"id":273,"tagName":"SCRIPT","attributes":{"type":"text/javascript","async":"","src":"http://px.owneriq.net/j/?pt=cx9r07&t=f%7C%22Big%2520George's%2520for%2520everything%2520from%2520Electrolux%2520Appliances%2520to%2520Napoleon%2520Fireplaces%22"},"previousSibling":{"id":270},"parentNode":{"id":148}}],"attributes":[],"text":[]}]
		
		@c.createSession
			name: 'large_event_test' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: false
		@c.on 'notifications_start', =>
			console.log('broadcasting')
			@c.broadcast deep: data
			.catch (e) ->
				done(e)
		@c.on 'event', (event) ->
			event.data().deep.should.deep.equal data
			done()
			
	it 'should be able to read event data multiple times', (done) ->
		this.timeout(5000)
		data = {deep: 'potlee'}
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: false
		.catch (error) ->
			done(error)
		@c.on 'notifications_start', =>
			@c.broadcast data
			.catch (e) ->
				done(e)
		@c.on 'event', (event) ->
			data1 = event.data()
			data2 = event.data()
			data1.should.deep.equal data
			data2.should.deep.equal data
			done()
		@c.on 'notifications_error', (error) ->
			done(error)
	
	it 'should have consistent data for broadcasted and received event', (done) ->
		this.timeout(5000)
		data = {deep: 'potlee'}
		broadcasted = undefined
		@c.on 'error', (err) ->
			done(err)
		@c.on 'event', (received) ->
			console.trace()
			console.log JSON.stringify(broadcasted)
			console.log JSON.stringify(received)
			broadcasted.order_id.should.deep.equal received.order_id
			broadcasted.data().should.deep.equal received.data()
			broadcasted.rawData().should.deep.equal received.rawData()
			broadcasted.author.should.deep.equal received.author
			broadcasted.event_type.should.equal received.event_type
			done()
		@c.on 'notifications_start', =>
			@c.broadcast data, "type"
			.then (b_event) ->
				broadcasted = b_event
				console.log JSON.stringify(broadcasted)
				#@c.resumeEvent
		@c.on 'notifications_error', (error) ->
			done(error)
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password'
			tags: ['node_test_session']
			startPaused: true
		
	it 'should create session', (done) ->
		@c.createSession
			name: 'create_session_test' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then (session) =>
			session.session_name.split('_').should.have.length 3
			session.session_tag[0].should.equal 'node_test_session'
			@c.session.session_tag[0].should.equal 'node_test_session'
			done()
		@c.on 'notifications_start', ->
			#alert 'start'
		@c.on 'notifications_error', (error) ->
			done(error)

	it 'should create session with basefile and join it', (done) ->
		@timeout 10000
		@c.createSession
			name: 'session_basefile_test' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
			baseFile: {aa: Array(20).join('a'), bb: Array(1024*900).join('b'), a: 'basefile'}
		.then (created_session) =>
			@c.joinSession 
				session: created_session
				password: 'password'
			.then (session) ->
				session.baseFile.a.should.equal 'basefile'
				console.log session.baseFile
				#session.baseFile.aa[999].should.equal 'p'
				done()
		.catch (e) ->
			console.log(e)
			done(e)

	it 'should look for sessions with filter tags', (done) ->
		@timeout 4000
		nonce = Math.random().toString()
		@c.createSession
			name: nonce
			tags: [nonce, 'filterMatch']
		.then (session) =>
			@c.listSessions [nonce]
			.then (list) =>
				list.should.be.an 'Array'
				list.should.not.be.empty
				match_name = (session_el) -> session.session_name == session_el.session_name
				list.some(match_name).should.be.true
				done()
			.catch (e) ->
				done(e)

	it 'should look for session with exact match tags', (done) ->
		@timeout 4000
		nonce = Math.random().toString()
		console.log nonce
		@c.createSession
			name: nonce
			tags: [nonce, 'exactMatch']
		.then (session) =>
			@c.listSessions [nonce], true
			.then (list) =>
				console.log list
				list.should.be.an 'Array'
				list.should.be.empty
				done()
			.catch (e) ->
				done(e)
				
	it 'should leave session', (done) ->
		@timeout 3000
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then =>
			@c.leaveSession()
		.then =>
			String(@c.session).should.equal 'undefined'
			done()
		.catch (e) ->
			done(e)

	it 'should end session', (done) ->
		@timeout 3000
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
		.then =>
			@c.endSession()
		.then =>
			String(@c.session).should.equal 'undefined'
			done()
		.catch (e) ->
			done(e)

	it 'should prevent further joins', (done) ->
		@timeout 5000
		tag = 'node_test_session' + Math.random().toString()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: [tag]
			startPaused: false
			baseFile: {this: 'is', a: 'basefile'}
		.then =>
			@c.preventFurtherJoins()
		.then ->
			done()
		.catch (e) ->
			done(e)

	it 'should start notifications', (done) ->
		this.timeout(5000)
		@c.on 'notifications_start', ->
			done()
		@c.on 'notifications_error', (error) ->
			done(error)
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false

	it 'should add participant', (done) ->
		this.timeout(5000)
		participant = new Participant
			participant_id: 1234
			
		addParticipantNotfication = new Notification_AddParticipant
			participant_id: participant.participant_id
			participant: participant
			
		addParticipantWrapper = new CollabrifyNotification
			notification_message_type: 2 #Collabrify.NotificationMessageType['ADD_PARTICIPANT_NOTIFICATION']
			payload: addParticipantNotfication.encode().toBuffer()
				
		@c.on 'notifications_start', =>
			@c.session.socket.onmessage {data: addParticipantWrapper.toBase64()}
		@c.on 'user_joined', (joined_participant) ->
			if(joined_participant.participant_id.equals participant.participant_id)
				done()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false

	it 'should remove participant', (done) ->
		this.timeout(5000)
		participant = new Participant
			participant_id: 1234
			
		addParticipantNotfication = new Notification_AddParticipant
			participant_id: participant.participant_id
			participant: participant
			
		addParticipantWrapper = new CollabrifyNotification
			notification_message_type: 2 #Collabrify.NotificationMessageType['ADD_PARTICIPANT_NOTIFICATION']
			payload: addParticipantNotfication.encode().toBuffer()
		
		removeParticipantNotification = new Notification_RemoveParticipant
			particpant: participant
		
		removeParticipantWrapper = new CollabrifyNotification
			notification_message_type: 4 #Collabrify.NotificationMessageType['REMOVE_PARTICIPANT_NOTIFICATION']
			payload: removeParticipantNotification.encode().toBuffer()
		@c.on 'notifications_start', =>
			@c.session.socket.onmessage {data: addParticipantWrapper.toBase64()}
			@c.session.socket.onmessage {data: removeParticipantWrapper.toBase64()}
		@c.on 'user_left', (removed_participant) ->
			if(removed_participant.participant_id.equals participant.participant_id)
				done()
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false
			
	it 'should reconnect on channel error', (done) ->
		this.timeout(5000)
		@c.eventEmitter.once 'notifications_start', =>
			console.log 'first notification start'
			@c.on 'notifications_start', ->
				console.log 'second notification start'
				done()
			@c.session.socket.onerror('error')
		@c.createSession
			name: 'node_test_session' + Math.random().toString()
			password: 'password' 
			tags: ['node_test_session']
			startPaused: false