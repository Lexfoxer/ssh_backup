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
dirDownload = './backup/'


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
, 2

# for k, v of servers
# 	aSync.push v

aSync.push servers['visible.name']


createZip = (server, callback)->
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
			console.log 'ZIP successful created ' + server.path
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
						console.log '\nDownload successful: ' + server.path 
	}
	.start()




