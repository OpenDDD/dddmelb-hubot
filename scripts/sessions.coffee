# Description:
#   Performs actions on the DDD sessions
#
# Dependencies:
#   None
#
# Commands:
#   hubot sessions - List all the sessions requiring approval
#   hubot sessions approve "<sessionIds>" - Approves the sessions supplied in the comma-separated list of session ids
#
# Author:
#   Neil Campbell

module.exports = (robot) ->

  robot.respond /sessions/i, (msg) ->
    msg.reply "Here are the sessions"