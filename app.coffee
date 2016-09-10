'use struct'
# 
# Import  
# 
SSH = require 'simple-ssh'
client = require 'scp2'
tress = require 'tress'
fsExtra = require 'fs-extra'
servers = require './_DB.js'
preloader = require './preloader.js'


# 
# Global
# 
d = new Date()
DATE = d.getDate()+'.'+(d.getMonth()+1)+'.'+d.getUTCFullYear();
dirDownload = './backup.'+DATE+'/'


# 
# Class Timer
# 
class Timer
	@time: ''
	constructor: (title)->
		@title = title
		@start()
	start: ()->
		@start_time = new Date().getTime()
	end: ()->
		@end_time = new Date().getTime()
		@time = " (#{@title}: #{(@end_time - @start_time) / 1000}s)"


# Create Dir
fsExtra.emptyDir dirDownload, (err)->
	if err
		console.error err


# Create queue
aSync = tress (server, done)->
	createZip server, (err, data)->
		if err
			done err
		else
			done null, data
, 1

# 
# Push to queue
# 
for k, v of servers
	aSync.push v


# 
# Function Create Zip & Download this
# 
createZip = (server, callback)->
	backup_time = new Timer 'time'

	console.log "\n⡇Run backup " + server.user
	serv = new SSH {
			host: server.host
			user: server.user
			passphrase: server.passphrase
			key: server.privateKey
		}

	serv.on 'error', (err)->
		if err
			throw err
	preloader.edit_text 'Create zip "'+server.path+'"'
	serv.exec 'zip -r ' + server.zip, {
		out: (stdout)->
			preloader.step()
		exit: (code, stdout, stderr)->
			process.stdout.clearLine()
			process.stdout.cursorTo(0)
			backup_time.end()
			console.log '⡇ZIP successful created ' + server.path + backup_time.time
			if code != 0
				callback code
			else
				preloader.start 'Download '+server.path
				client.scp {
						host: server.host
						username: server.user
						passphrase: server.passphrase
						privateKey: server.privateKey
						path: server.path
					}, dirDownload, (err)->
						preloader.stop()
						if err
							console.log err
						backup_time.end()
						process.stdout.clearLine()
						process.stdout.cursorTo(0)
						console.log '⡇Download successful: ' + server.path + backup_time.time
						callback null, true
	}
	.start()




