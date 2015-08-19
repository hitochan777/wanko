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
#   hubot branch [merge|delete] <repo_name>/<head> into <base> [with <tag>]- merge branches
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

  robot.respond /branch merge ([-_\.0-9a-zA-Z]+)(?:\/([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)(?: with ([-_\.a-zA-z0-9\/]+))?$/i, (res)->
  
    github.handleErrors (response) ->
      res.send "#{response.statusCode} #{response.error}... I sincerely apologize for this."

    repo = res.match[1]
    head = res.match[2]
    base = res.match[3]
    tag = res.match[4]

    url = "#{url_api_base}/repos/#{owner}/#{repo}/merges" #GitHubAPIのURL

    # account_name = res.envelope.user.name || "anonymous" #このスクリプトを呼び出した人のSlackアカウント名
    # channel_name = res.envelope.room || "anonymous" #このスクリプトを呼び出したSlackのChannel

    res.send "I am gonna merge... wait patiently"
    
    data = {
      "base": base,
      "head": head
    }

    github.post url, data, (merge_res) ->
      unless merge_res?
        res.send "There is nothing to do."
        return
      res.send "done merging"
      if tag?
        url = "#{url_api_base}/repos/#{owner}/#{repo}/git/tags" # URL for Tag API in github
        data = {
          "tag": tag,
          "message":"Release #{tag}",
          "object": merge_res.sha,
          "type": "commit"
        }
        github.post url, data, (tag_res) ->
          url = "#{url_api_base}/repos/#{owner}/#{repo}/git/refs" # URL for Reference API in github
          res.send "tag obj created"
          data = {
            "ref":"refs/tags/#{tag}"
            "sha":tag_res.sha
          }
          github.post url, data, (ref_res) ->
            res.send "tagged with #{tag}"
  
  robot.respond /branch delete ([-_\.0-9a-zA-Z]+)\/([-_\.a-zA-z0-9\/]+)$/i, (res)->
    github.handleErrors (response) ->
      res.send "#{response.statusCode} #{response.error}... I sincerely apologize for this."

    repo = res.match[1]
    ref = res.match[2]
    url = "#{url_api_base}/repos/#{owner}/#{repo}/git/refs/heads/#{ref}" #GitHubAPIのURL
    res.send url
    github.delete url, (del) ->
      res.send "#{ref} in #{repo} was successfully deleted"
