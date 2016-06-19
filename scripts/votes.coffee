# Description:
#   Performs actions on the DDD votes
#
# Dependencies:
#   "azure-storage": "0.4.4"
#
# Configuration:
#   AZURE_STORAGE_CONNECTION_STRING
#
# Commands:
#   dddmelb votes - List votes for sessions
#
# Author:
#   Neil Campbell

azure = require('azure-storage')
_ = require('lodash');

tableSvc = azure.createTableService()

listVotes = (msg) -> 
  query = new azure.TableQuery()
    .where('CorrectEmail eq ?', true)
    .and('ValidOrder eq ?', true)

  tableSvc.queryEntities('Votes', query, null, (err, result, response) -> 
    if err
      msg.reply "Something's broken, I couldn't find any votes"
      return

    if !result.entries or result.entries.length == 0
      return
      
    votesBySession = _.groupBy(result.entries, (vote) -> vote.SessionId._)
    orderedVotesBySession = _.orderBy(votesBySession, [(votes) -> votes.length], ['desc'])

    for votesForSession in orderedVotesBySession
      msg.reply "\n
*Title:* (#{votesForSession[0].SessionId._}) \n
*Votes:* #{votesForSession.length}"
  )

module.exports = (robot) ->
  robot.respond /votes$/, (msg) ->
    msg.reply "Getting votes for sessions..."
    listVotes(msg)