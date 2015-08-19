# Description:
#   create pull requests in a Github repository
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_API
#
# Commands:
#   hubot delete (branch|tag) <repo_name>/<head> - delete branch or tag
#
# Author:
#   hitochan777

module.exports = (robot) ->

  github = require("githubot")(robot)
  owner = process.env.HUBOT_GITHUB_OWNER

  unless (url_api_base = process.env.HUBOT_GITHUB_API)?
    url_api_base = "https://api.github.com"
    
  robot.respond /delete (branch|tag) ([-_\.0-9a-za-z]+)\/([-_\.0-9a-za-z\/]+)$/i, (res)->
    ref_type = if res.match[1] == "branch"
      "heads"
    else
      "tags"
    repo = res.match[2]
    ref = res.match[3]
    
    url = "#{url_api_base}/repos/#{owner}/#{repo}/git/refs/#{ref_type}/#{ref}" #GitHubAPIのURL
    # res.send url 
    github.delete url, (del) ->
      res.send "#{ref} in #{repo} was successfully deleted"
