module.exports = (robot) ->
  robot.catchAll (res) ->
    res.send "I don't know how to react to: #{res.message.text}"
