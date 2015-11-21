# Description:
#   List "setters" and the "find me a team" conversation machine
#
# Dependencies:
#   redis-brain, if you want your users' database to persist from
#     one running hubot process onto the next
#
# Configuration:
#   None
#
# Commands:
#   hubot find me a team - Let me know if you need teammates
#   hubot list me - Let me know that you need more team members
#   hubot unlist me - Let me know that you already formed a team
#   hubot I have an idea -
#   hubot I know Microsoft Excel -

setLang = (user, mat, brn) ->
  brn.set "language:#{user}", mat
  users = brn.get "users"
  users = {} if users == null
  users[user] = {language: mat}
  brn.set "users", users

addIdea = (user, mat, brn) ->
  brn.set "ideas:#{user}", mat
  ideas = brn.get "ideas"
  ideas = [] if ideas == null
  ideas.push {idea: mat, username: user}
  brn.set "ideas", ideas

flipFlop = (user, sta, par, job, mat, brn) ->
  if (sta == par)
    userstate2 = brn.get "state:#{user}:#{par}"
    if (userstate2 == null)
      brn.set "state:#{user}:#{par}", true
      return false
    else
      brn.set "state:#{user}:#{par}", null
      job mat
      return true

dumpObj = (obj) ->
  o = "{"
  for own key, value of obj
    v = value
    if key == "envelope" || key == "user" #|| key == "robot"
      v = dumpObj value
    o = o + "#{key}: #{v},"
  o = o + "}"

module.exports = (robot) ->

  robot.respond /save\s+(.*)/i, (res) ->
    robot.brain.set "memory:#{msg.envelope.user.name}", res.match[1]
    res.send "OK, got it."
    
  robot.respond /recall/i, (msg) ->
    memory = robot.brain.get "memory:#{msg.envelope.user.name}"
    msg.send memory

  robot.respond /dump\s*(.*)/i, (res) ->
    o = dumpObj res
    res.send o

  robot.respond /list me/i, (msg) ->
    username = msg.envelope.user.name
    robot.brain.set "listed:#{username}", true
    t = "#{username}: OK, I will help you find you a team.\n"
    t = t + "Try '#{robot.name} unlist me' if you don't want yourself or your ideas to show on the list."
    lang = robot.brain.get "language:#{username}"
    t = t + "\nTry '#{robot.name} I know COBOL' to tell what language you like to code with" if lang == null
    msg.send t

  robot.respond /I know (.*)/i, (res) ->
    mat = res.match[1]
    username = res.envelope.user.name
    setLang username, mat, robot.brain
    robot.brain.set "language:#{username}", mat
    l = robot.brain.get "listed:#{username}"
    t = "Thanks.  I'll be sure to mention it."
    t = t + "\nNeed a team?  Try '#{robot.name} list me' to share your skills." if !l
    res.send t

  robot.respond /unlist me/i, (msg) ->
    username = msg.envelope.user.name
    robot.brain.set "listed:#{username}", false
    msg.send "#{username}: OK, I won't list you or your project ideas anymore."

  robot.hear /who am i/i, (msg) ->
    msg.send "You are @#{msg.envelope.user.name}!  Did you forget?"

  robot.respond /(find|get) me a( new)? team/i, (msg) ->
    username = msg.envelope.user.name
    msg.send "OK, what programming language do you use"
    robot.brain.set "state:#{username}", "ask for language"

  robot.respond /i have an idea/i, (msg) ->
    username = msg.envelope.user.name
    msg.send "What's your idea, #{username}?"
    robot.brain.set "state:#{username}", "has an idea"

  robot.hear ///(#{robot.name}.?\s+)?(.*)///, (res) ->
    username = res.envelope.user.name
    userstate = robot.brain.get "state:#{username}"
    match = res.match[2]

    parentState = "has an idea"
    doTheJob = (mat) ->
      addIdea username, mat, robot.brain
      robot.brain.set "state:#{username}", ""
      l = robot.brain.get "listed:#{username}"
      t = "Got it."
      t = t + "\nNeed a team?  Try '#{robot.name} list me' to share your idea." if !l
      res.send t
    return null if flipFlop username, userstate, parentState, doTheJob, match, robot.brain

    parentState = "ask for language"
    saveLanguage = (mat) ->
      setLang username, mat, robot.brain
      res.send "Got it.  Do you know what you want to build?"
      newState = "ask if idea"
      robot.brain.set "state:#{username}", newState
      flipFlop username, newState, newState, askForIdea, match, robot.brain
    return null if flipFlop username, userstate, parentState, saveLanguage, match, robot.brain

    parentState = "ask if idea"
    askForIdea = (mat) ->
      if mat.match /yes/i
        res.send "What is your idea?"
        newState = "what is idea"
        robot.brain.set "state:#{username}", newState
        flipFlop username, newState, newState, askForIdea, match, robot.brain
      else if mat.match /no/i
        res.send "OK... try '#{robot.name} list ideas'"
        robot.brain.set "state:#{username}", "next"
        #
      else
        res.send "I didn't get that... yes or no?"
        flipFlop username, parentState, parentState, askForIdea, match, robot.brain
    return null if flipFlop username, userstate, parentState, askForIdea, match, robot.brain

    noop = () ->
      a = ""

    parentState = "what is idea"
    saveIdea = (mat) ->
      res.send "Thanks, @#{username}, do you want your idea to be listed?"
      newState = "saveAdvPreference"
      addIdea username, mat, robot.brain
      robot.brain.set "state:#{username}", newState
      flipFlop username, newState, newState, noop, match, robot.brain
    flipFlop username, userstate, parentState, saveIdea, match, robot.brain

    parentState = "saveAdvPreference"
    saveAdvPreference = (mat) ->
      if mat.match /yes/
        res.send "I'll add you to the list.  Use '#{robot.name} list users' or '#{robot.name} list ideas' to look for other hackers who can still form a team."
        newState = "next"
        robot.brain.set "state:#{username}", newState
        robot.brain.set "listed:#{username}", true
        flipFlop username, newState, newState, noop, match, robot.brain
      else if mat.match /no/
        res.send "OK.  I won't tell anyone."
        robot.brain.set "listed:#{username}", false
        robot.brain.set "state:#{username}", "next"
      else
        res.send "I didn't get that... yes or no?"
        flipFlop username, parentState, parentState, noop, match, robot.brain
    flipFlop username, userstate, parentState, saveAdvPreference, match, robot.brain


#  robot.brain.save "team-ideas:#{msg.envelope.user.name}", idea
