# Description:
#   Performs actions on the DDD sessions
#
# Dependencies:
#   None
#
# Commands:
#   hubot sessions - List all the sessions requiring approval
#   hubot sessions approve <sessionIds> - Approves the sessions supplied in the comma-separated list of session ids
#
# Author:
#   Neil Campbell

azure = require('azure-storage')

tableSvc = azure.createTableService()

listUnapprovedSessions = (msg) -> 
  query = new azure.TableQuery()
    .top(10)
    .where('Status eq ?', 0)

  tableSvc.queryEntities('Sessions', query, null, (err, result, response) -> 
    if err
      msg.reply "Error getting sessions"
      return

    if !result.entries or result.entries.length == 0
      msg.reply "Yay, none to approve."
      return

    for session in result.entries
      msg.reply "Id: #{session.RowKey._} \nTitle: #{session.SessionTitle._} \nAbstract: #{session.SessionAbstract._}"
  )

approve = (msg, sessionId) ->   
  session = 
    PartitionKey: { '$': 'Edm.String', _: 'Session' }
    RowKey: { '$': 'Edm.String', _: sessionId }
    Status: { _: 1 }

  tableSvc.mergeEntity('Sessions', session, (err, result, response) -> 
    if err
      msg.reply "Error updating session '#{sessionId}'"
      return

    msg.reply "'#{sessionId}' has been approved"
  )

module.exports = (robot) ->
#(?<![\w\d])abc(?![\w\d])
  robot.respond /sessions$/, (msg) ->
    msg.reply "Finding sessions requiring approval (max 10)..."
    listUnapprovedSessions(msg)

  robot.respond /sessions approve (.*)/i, (msg) ->
    sessionIds = msg.match[1].split(',')

    if !sessionIds or sessionIds.length == 0
      msg.replay "Please supply some sessions."
      return

    msg.reply "Approving sessions..."
    approve(msg, sessionId.trim()) for sessionId in sessionIds