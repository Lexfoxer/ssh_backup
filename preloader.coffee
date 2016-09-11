arr1 = ['⁘','⁜','⁙']
arr2 = ['⋮','⋰','⋯','⋱']
arr3 = ['▖','▘','▝','▗']
arr4 = ['▙','▛','▜','▟']
arr5 = ['☰','☴','☶','☷','☳','☱']
arr6 = ['⠀','⠁','⠃','⠇','⡇','⣇','⣧','⣷','⣿','⣾','⣼','⣸','⢸','⠸','⠘','⠈']


class Preloader
	constructor: (text = '') ->
		@text = text
		@runs = false
		@loadStep = 0
		@arr = arr6

	edit_text: (text)->
		@text = text

	remove: (in_text = '')->
		@stop()
		process.stdout.clearLine()
		process.stdout.cursorTo(0)
		if in_text != ''
			console.log in_text

	start: (text = '')->
		if @runs == false
			if text != ''
				@text = text
			@runs = true
			@auto()

	stop: ()->
		if @runs == true
			@runs = false

	auto: ()->
		sI = setInterval ()=>
			@step()
		,100
		time = setInterval ()=>
			if @runs == false
				clearTimeout sI
				clearTimeout time
		,10

	step: ()->
		process.stdout.clearLine()
		process.stdout.cursorTo(0)
		process.stdout.write @text + ' ' + @arr[@loadStep] + ' '
		@loadStep++
		if @loadStep == (@arr.length)
			@loadStep = 0






module.exports = new Preloader ''
