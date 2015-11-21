# Description:
#   List "getters"
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot list users - Show un-teamed users listed by language
#   hubot list ideas - Show the list of ideas from un-teamed users
#   hubot idea #n - Ask whose idea is idea #n to join their team

module.exports = (robot) ->

#   hubot forget everything - Please don't take my brain!
#  robot.respond /forget everything/, (msg) ->
#    robot.brain.set "_private" # This won't work because redis-brain plugin
#
  robot.respond /list users/i, (msg) ->
    users = robot.brain.get "users"
    users = {} if users == null
    t = ""
    c = 0
    unless Object.keys(users).length == 0
      for username, fields of users
        l = robot.brain.get "listed:#{username}"
        t = t + "@#{username}: #{fields.language}\n" if l
        c = c + 1 if l
      t = t + "To remove yourself from this list, try '#{robot.name} unlist me'" if robot.brain.get "listed:#{msg.envelope.user.name}"
    else
      msg.send "No users so far!  Try '#{robot.name} find me a team'"
      return false
    if c > 0
      msg.send "These hackathon participants are listed by their chosen language:"
      msg.send t
    else
      msg.send "Nobody is listed as unteamed.  Try '#{robot.name} list me', '#{robot.name} find me a team', or '#{robot.name} help'."

  robot.respond /list ideas/i, (msg) ->
    ideas = robot.brain.get "ideas"
    ideas = [] if ideas == null
    t = ""
    c = 0
    if ideas.length > 0
      for obj, i in ideas
        l = robot.brain.get "listed:#{obj.username}"
        t = t + "##{i+1}: #{obj.idea}\n" if l
        c = c + 1 if l
    else
      t = t + "No ideas so far!\n"
      t = t + "Try '#{robot.name} list me' or '#{robot.name}, I have an idea', or\n"
      t = t + "try '#{robot.name} list users' to find more people that need a team."
      msg.send t
      return false
    if c > 0
      t = t + "Say '#{robot.name} idea #N' if you want to join a team, or \n"
      t = t + "say '#{robot.name} I have an idea' to list your own idea.\n"
      (t = t + "You can also '#{robot.name} list me'") if !robot.brain.get "listed:#{obj.username}"
      msg.send t
    else
      t = t + "No ideas in my brain.  Try '#{robot.name} find me a team'\n"
      t = t + "or type '#{robot.name} i have an idea'!"
      msg.send t

  robot.respond /idea #(\d+)/i, (res) ->
    n = res.match[1]
    ideas = robot.brain.get "ideas"
    idea = ideas[n-1]
    res.send "Idea #{n}: talk to @#{idea.username}"
    
