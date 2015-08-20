# Description
#   Assign roles to users and restrict command access in other scripts.
#
# Configuration:
#   HUBOT_AUTH_ADMIN - A comma separate list of user IDs
#
# Commands:
#   hubot <user> has <role> role - Assigns a role to a user
#   hubot <user> doesn't have <role> role - Removes a role from a user
#   hubot what roles does <user> have - Find out what roles a user has
#   hubot what roles do I have - Find out what roles you have
#   hubot who has <role> role - Find out who has the given role
#
# Notes:
#   * Call the method: robot.auth.hasRole(res.envelopee.user,'<role>')
#   * returns bool true or false
#
#   * the 'admin' role can only be assigned through the environment variable
#   * roles are all transformed to lower case
#
#   * The script assumes that user IDs will be unique on the service end as to
#     correctly identify a user. Names were insecure as a user could impersonate
#     a user

config =
  admin_list: process.env.HUBOT_AUTH_ADMIN

module.exports = (robot) ->

  unless config.admin_list?
    robot.logger.warning 'The HUBOT_AUTH_ADMIN environment variable not set'

  if config.admin_list?
    admins = config.admin_list.split ','
  else
    admins = []

  class Auth
    isAdmin: (user) ->
      user in admins

    hasRole: (user, roles) ->
      userRoles = @userRoles(user)
      if userRoles?
        roles = [roles] if typeof roles is 'string'
        for role in roles
          return true if role in userRoles
      return false

    usersWithRole: (role) ->
      users = []
      for own key, user of robot.brain.data.users
        if @hasRole(user, role)
          users.push(user.name)
      users

    userRoles: (user) ->
      roles = []
      if user? and robot.auth.isAdmin user
        roles.push('admin')
      if user.roles?
        roles = roles.concat user.roles
      roles

  robot.auth = new Auth

  robot.respond /what roles? do(es)? @?(.+) have\?*$/i, (res) ->
    name = res.match[2]
    if name.toLowerCase() is 'i' then name = res.envelope.user.name
    user = robot.brain.userForName(name)
    return res.reply "#{name} does not exist" unless user?
    userRoles = robot.auth.userRoles(user)

    if userRoles.length == 0
      res.reply "#{name} has no roles."
    else
      res.reply "#{name} has the following roles: #{userRoles.join(', ')}."

  robot.respond /who has (["'\w: -_]+) role\?*$/i, (res) ->
    role = res.match[1]
    userNames = robot.auth.usersWithRole(role) if role?

    if userNames.length > 0
      res.reply "The following people have the '#{role}' role: #{userNames.join(', ')}"
    else
      res.reply "There are no people that have the '#{role}' role."

  robot.respond /@?(.+) ha(s|ve) (["'\w: -_]+) role/i, (res) ->
    if res.match[1].toLowerCase() in ['who', 'what', 'where', 'when', 'why']
      return

    unless robot.auth.isAdmin res.envelope.user.name
      res.reply "Sorry, only admins can assign roles."
    else
      name = res.match[1]
      if name.toLowerCase() is 'i' then name = res.envelope.user.name
      newRole = res.match[3].toLowerCase()

      unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
        user = robot.brain.userForName(name)
        return res.reply "#{name} does not exist" unless user?
        user.roles or= []

        if newRole in user.roles
          res.reply "#{name} already has the '#{newRole}' role."
        else
          if newRole is 'admin'
            res.reply "Sorry, the 'admin' role can only be defined in the HUBOT_AUTH_ADMIN env variable."
          else
            myRoles = res.envelope.user.roles or []
            user.roles.push(newRole)
            res.reply "OK, #{name} has the '#{newRole}' role."

  robot.respond /@?(.+) do(n't|esn't|es)( not)? have (["'\w: -_]+) role/i, (res) ->
    unless robot.auth.isAdmin res.envelope.user.name
      res.reply "Sorry, only admins can remove roles."
    else
      name = res.match[1]
      if name.toLowerCase() is 'i' then name = res.envelope.user.name
      newRole = res.match[4].toLowerCase()

      unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
        user = robot.brain.userForName(name)
        return res.reply "#{name} does not exist" unless user?
        user.roles or= []

        if newRole is 'admin'
          res.reply "Sorry, the 'admin' role can only be removed from the HUBOT_AUTH_ADMIN env variable."
        else
          myRoles = res.envelope.user.roles or []
          user.roles = (role for role in user.roles when role isnt newRole)
          res.reply "OK, #{name} doesn't have the '#{newRole}' role."

