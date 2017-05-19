# Description:
#   Performs actions on the DDD sessions
#
# Dependencies:
#   "azure-storage": "0.4.4"
#
# Configuration:
#   AZURE_STORAGE_CONNECTION_STRING
#
# Commands:
#   dddmelb sessions - List sessions that requiring approval (max 10)
#   dddmelb sessions approve <sessionIds> - Approves the sessions supplied in the comma-separated list of session ids
#
# Author:
#   Neil Campbell

azure = require('azure-storage')
request = require('request')

tableSvc = azure.createTableService()

listUnapprovedSessions = (msg) ->
  query = new azure.TableQuery()
    .top(10)
    .where('Status eq ?', 0)

  tableSvc.queryEntities('Sessions', query, null, (err, result, response) ->
    if err
      msg.reply "Something's broken, I couldn't find any sessions"
      return

    if !result.entries or result.entries.length == 0
      msg.reply "Yay, no sessions to approve"
      return

    for session in result.entries
      msg.reply "\n
*Id:* #{session.RowKey._} \n
*Presenter:* #{session.PresenterName._} \n
*Title:* #{session.SessionTitle._} \n
*Abstract:* #{session.SessionAbstract._}"

    msg.reply "To approve all sessions run `sessions approve #{result.entries.map((s) -> s.RowKey._).join(',')}`"
  )

approve = (msg, sessionId) ->
  session =
    PartitionKey: { '$': 'Edm.String', _: 'Session' }
    RowKey: { '$': 'Edm.String', _: sessionId }
    Status: { _: 1 }

  tableSvc.mergeEntity('Sessions', session, (err, result, response) ->
    if err
      msg.reply "Something's wrong, I couldn't approve '#{sessionId}'"
      return

    msg.reply "'#{sessionId}' is now approved"
  )

module.exports = (robot) ->
  robot.respond /sessions$/, (msg) ->
    msg.reply "Searching for unapproved sessions..."
    listUnapprovedSessions(msg)

  robot.respond /sessions approve (.*)/i, (msg) ->
    sessionIds = msg.match[1].split(',')

    if !sessionIds or sessionIds.length == 0
      msg.replay "You haven't given me any sessions mate"
      return

    msg.reply "Approving sessions..."
    approve(msg, sessionId.trim()) for sessionId in sessionIds

    #deploy the sessions
    options = {
      url: 'https://app.wercker.com/api/v3/runs',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + process.env.WERCKER_KEY
      },
      json: {
        'pipelineId': '5917ed805dec090100cdaf2d',
        'branch': 'master',
        'message': 'Refresh site data'
      }
    }

    request.post(options, (err, res, body) ->
        if !err and res.statusCode == 200
          msg.reply "Deploying data updates..."
    )
