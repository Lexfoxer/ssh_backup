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
	createZip server, (err)->
		if err
			done err
		else
			rmTemp server, (err, data)->
				if err
					done err
				done null
, 1


# 
# Push to queue
# 
for k, v of servers
	aSync.push v


# 
# Function Create Zip & Download this
# 
createZip = (server, callback_queue)->
	filenameMySQL = server.user+'.'+DATE+'.sql.gz'
	filenameFTP = server.user+'.'+DATE+'.zip'
	createTempFolder = 'mkdir -m 700 '+server.temp_folder
	backupMySQL = 'mysqldump -u '+server.db_user+' -p'+server.db_pass+' '+server.db_name+' | gzip > '+server.temp_folder+filenameMySQL
	backupFTP = 'zip -r '+server.temp_folder+filenameFTP+' '+server.zip

	backup_time = new Timer 'time'
	console.log "\n⡇Run backup "+server.user

	servShell = new SSH {
			host: server.host
			user: server.user
			passphrase: server.passphrase
			key: server.privateKey
		}

	servShell.on 'error', (err)->
		if err
			callback_queue err

	servShell
		.exec createTempFolder, {
			in: ()->
				preloader.edit_text 'Create backup folder'
				preloader.start()
			exit: (code, stdout, stderr)->
				backup_time.end()
				if code != 0
					preloader.remove()
					callback_queue stderr
				else
					preloader.remove('⡇Backup folder created "'+server.temp_folder+'"'+backup_time.time)
		}

		.exec backupMySQL, {
			in: ()->
				preloader.edit_text 'Create GZIP DB "'+filenameMySQL+'"'
			out: (stdout)->
				preloader.start()
			exit: (code, stdout, stderr)->
				backup_time.end()
				if code != 0
					preloader.remove()
					callback_queue stderr
				else
					preloader.remove '⡇GZIP DB successful created "'+filenameMySQL+'"'+backup_time.time
		}

		.exec backupFTP, {
			in: ()->
				preloader.edit_text 'Create ZIP "'+filenameFTP+'"'
			out: (stdout)->
				preloader.step()
			exit: (code, stdout, stderr)->
				backup_time.end()
				if code != 0
					preloader.remove()
					callback_queue stderr
				else
					preloader.remove '⡇ZIP successful created "'+filenameFTP+'"'+backup_time.time
					downloadFile servShell, backup_time, server, filenameFTP, (err)->
						if err
							callback_queue err
						downloadFile servShell, backup_time, server, filenameMySQL, (err)->
							if err
								callback_queue err
							servShell.end()
							callback_queue null
		}
	.start()


rmTemp = (server, done)->
	serverShell = new SSH {
			host: server.host
			user: server.user
			passphrase: server.passphrase
			key: server.privateKey
		}
	removeTempFolder = 'rm -r '+server.temp_folder
	serverShell.exec removeTempFolder, {
		in: ()->
			preloader.edit_text 'Remove temp folder "'+server.temp_folder+'"'
			preloader.start()
		exit: (code, stdout, stderr)->
			if code != 0
				preloader.remove()
				done stderr
			else
				preloader.remove '⡇Remove temp folder successful '+server.temp_folder
				serverShell.end()
				done null, true
	}
	.start()


downloadFile = (serverShell, backup_time, server, filename, done)->
	preloader.edit_text 'Download "'+server.temp_folder+filename+'"'
	preloader.start()
	client.scp {
		host: server.host
		username: server.user
		passphrase: server.passphrase
		privateKey: server.privateKey
		path: server.temp_folder+filename
	}, dirDownload, (err)->
		if err
			preloader.remove()
			console.log err
			fs.unlink dirDownload+filename, (error)->
				if error
					done error
				done error
		else
			backup_time.end()
			preloader.remove '⡇Download successful "'+filename+'"'+backup_time.time
			done null






