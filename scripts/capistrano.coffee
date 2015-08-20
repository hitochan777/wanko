# Description:
#   merge pull requests in a Github repository
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   APP_ROOT_DIR
#
# Commands:
#   hubot deploy to <stage> <command> - deploy using capistrano
#
# Author:
#   hitochant777

module.exports = (robot) ->
  spawn = require('child_process').spawn
  carrier = require('carrier')

  unless process.env.APP_ROOT_DIR?
    console.log "You have to set APP_ROOT_DIR to env path!"
    return

  robot.respond /deploy to ([-_\.0-9a-zA-Z]+)\s*([-_\.0-9a-zA-Z]+)?$/i, (res)->
    stage = res.match[1]
    command = res.match[2] || ""
    if command != ""
      command = ":"+command
    res.send command+"hogege"

    account_name = res.envelope.user.name || "anonymous" #このスクリプトを呼び出した人のSlackアカウント名
    channel_name = res.envelope.room || "anonymous" #このスクリプトを呼び出したSlackのChannel
    
    cap = spawn("bundle", ["exec", "cap", "#{stage}", "deploy#{command}"],{
      cwd: process.env.APP_ROOT_DIR
    })
    capOut = carrier.carry cap.stdout
    capErr = carrier.carry cap.stderr

    capOut.on 'line', (line) ->
      res.send line

    capErr.on 'line', (line) ->
      res.send line
