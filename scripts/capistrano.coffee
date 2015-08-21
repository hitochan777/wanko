# Description
#   Deploy kuma using capistrano
#
# Configuration:
#   APP_ROOT_DIR - rails root dir
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Commands:
#   hubot deploy to :stage [:command] - deploy using capistrano
#
# Author:
#   hitochant777

SEND_INTERVAL = 1500 # ms

module.exports = (robot) ->
  spawn = require('child_process').spawn
  carrier = require('carrier')

  unless process.env.APP_ROOT_DIR?
    console.log "You have to set APP_ROOT_DIR to env path!"
    return

  robot.respond /deploy to ([-_\.0-9a-zA-Z]+)\s*([-_\.0-9a-zA-Z]+)?$/i, (res)->
    buffer = []
    timer = null
    ended = false
    unless robot.auth.hasRole(res.envelope.user.name,'deploy')
      res.reply "You don't have 'deploy' role"
      return

    stage = res.match[1]
    command = res.match[2] || ""
    if command != ""
      command = ":"+command

    account_name = res.envelope.user.name || "anonymous" #このスクリプトを呼び出した人のSlackアカウント名
    channel_name = res.envelope.room || "anonymous" #このスクリプトを呼び出したSlackのChannel
    
    cap = spawn("bundle", ["exec", "cap", "#{stage}", "deploy#{command}"],{
      cwd: process.env.APP_ROOT_DIR
    })

    cap.on 'close', (code) ->
      res.send "`Deploy has completed but I will show you the remaining log if any.`"
      ended = true
      buffer.push "Capistrano ended with exit code #{code}"
      if code==0
        buffer.push "`Deploy has succeeded!!`"
      else code==1
        buffer.push "`Deploy has failed`"

    capOut = carrier.carry cap.stdout
    capErr = carrier.carry cap.stderr

    timer = setInterval () ->
      if buffer.length > 0
        res.send buffer.shift()
      else if ended
        clearInterval timer
        timer = null
    , SEND_INTERVAL

    capOut.on 'line', (line) ->
      buffer.push line

    capErr.on 'line', (line) ->
      buffer.push line

