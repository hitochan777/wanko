# Description:
#   merge pull requests in a Github repository
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_API
#   HUBOT_GITHUB_OWNER
#
# Commands:
#   wanko [pr|pull request] send <repo_name>/<head> into <base> - send pull request
#   wanko [[pr|pull request] merge <repo_name>/<head> into <base> - merge pull request
#
# Author:
#   hitochant777

module.exports = (robot) ->
  github = require("githubot")(robot)
  owner = process.env.HUBOT_GITHUB_OWNER

  unless (url_api_base = process.env.HUBOT_GITHUB_API)?
    url_api_base = "https://api.github.com"
    
  _getDate = ->
    theDate = new Date
    yyyy = theDate.getFullYear()
    mm = theDate.getMonth()+1 #January is 0!
    if mm < 10
      mm = "0" + mm
    dd = theDate.getDate()
    if dd < 10
      dd = "0" + dd
    yyyy + "." + mm + "." + dd
          
  robot.respond /(?:pr|pull request) send ([-_\.0-9a-zA-Z]+)(\/([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)\ntitle: (.+)\ndesc: (.+)$/i, (res)->
    unless robot.auth.hasRole(res.envelope.user.name,'pr:send')
      res.reply "You don't have 'pr:send' role"
      return
    circleCIUrl = "https://circleci.com/gh/#{owner}/#{repo}/tree/#{encodeURIComponent(base)}" #CircleCIのURL
    repo = res.match[1]
    head = res.match[3]
    base = res.match[4]
    title = res.match[5] or "#{_getDate()} pull request by #{account_name}"
    desc = res.match[6] or """
      ・Created By #{account_name} on #{channel_name} Channel
      ・Circle CI build status can be shown: #{circleCIUrl}
    """

    url = "#{url_api_base}/repos/#{owner}/#{repo}/pulls" #GitHubAPIのURL
    
    account_name = res.envelope.user.name || "anonymous" #このスクリプトを呼び出した人のSlackアカウント名
    channel_name = res.envelope.room || "anonymous" #このスクリプトを呼び出したSlackのChannel
    
    data = {
      "title": title
      "body": body
      "head": head
      "base": base
    }
    
    github.post url, data, (pull) ->
      res.send "Pull request has been made " + pull.html_url

  robot.respond /(?:pr|pull request) merge ([-_\.0-9a-zA-Z]+)(\/([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+) (\d+)(?: with ([-_\.a-zA-z0-9\/]+))?$/i, (res)->
    unless robot.auth.hasRole(res.envelope.user.name,'pr:merge')
      res.reply "You don't have 'pr:merge' role"
      return
    repo = res.match[1]
    head = res.match[3]
    base = res.match[4]
    pr_num = res.match[5]
    tag = res.match[6]

    unless pr_num
      res.emit "You have to specify pull request number!"
      return

    url = "#{url_api_base}/repos/#{owner}/#{repo}/pulls/#{pr_num}/merge" #GitHubAPIのURL
    data = {}
    res.send "I am gonna merge... wait patiently\n#{url}"

    github.put url, data, (merge_res) ->
      res.send merge_res.message

