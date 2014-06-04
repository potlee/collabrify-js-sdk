EventEmitter = require('events').EventEmitter;

class OrderedEventEmitter extends EventEmitter
	orderedEvents: []
	nextEvent: 0

	emitOrdered: (event, argument) ->
		order_id = argument.order_id
		if @nextEvent == order_id.low
			@emit event, argument
			@nextEvent = @nextEvent + 1
			while @orderedEvents[@nextEvent]
				@emit event, @orderedEvents[@nextEvent]
				@orderedEvents[@nextEvent] = null
				@nextEvent = @nextEvent + 1
		else
			@orderedEvents[order_id.low] = argument

module.exports = OrderedEventEmitter
