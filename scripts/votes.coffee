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

retrieveVotes = (continuationToken) ->
  new Promise (resolve, reject) ->
    votesQuery = new azure.TableQuery()
      .where('CorrectEmail eq ?', true)
      .and('ValidOrder eq ?', true)
    entries = []
    tableSvc.queryEntities('Votes', votesQuery, continuationToken, (votesErr, votesResult, votesResponse) -> 
      if votesResult
        entries = votesResult.entries
        if (votesResult.continuationToken)
          retrieveVotes(votesResult.continuationToken).then (secondaryResult) ->
            Array.prototype.push.apply(entries, secondaryResult)
            resolve entries
        else
          resolve entries
      else
        reject Error votesErr
    )

listVotes = (msg) -> 
  sessionsQuery = new azure.TableQuery()
    .where('Status eq ?', 1)
  result = "\n"

  retrieveVotes(null).then (entries) ->
    # Ensure only the latest 10 votes for an attendee are counted
    votesByAttendee = _.groupBy(entries, (vote) -> vote.OrderNumber._)

    for attendee in Object.keys(votesByAttendee)
      if votesByAttendee[attendee].length > 10
        orderedVotes = _.orderBy(votesByAttendee[attendee], [(vote) -> vote.SubmittedDateUTC._], ['desc'])

        for voteToRemove in orderedVotes[10...]
          indexToRemove = entries.indexOf(voteToRemove)
          if indexToRemove > -1
            entries.splice(indexToRemove, 1)

    tableSvc.queryEntities('Sessions', sessionsQuery, null, (sessionsErr, sessionsResult, sessionsResponse) -> 
      if sessionsErr
        msg.reply "Something's broken, I couldn't find any sessions"
        return

      if !sessionsResult.entries or sessionsResult.entries.length == 0
        msg.reply "No sessions have been found"
        return
      votesBySession = _.groupBy(entries, (vote) -> vote.SessionId._)
      orderedVotesBySession = _.orderBy(votesBySession, [(votes) -> votes.length], ['desc'])

      nOrder = 1
      for votesForSession in orderedVotesBySession
        sessionId = votesForSession[0].SessionId._
        session = _.find(sessionsResult.entries, (session) -> session.RowKey._ == sessionId)
        result += "#{nOrder}. #{session.SessionTitle._} - #{session.PresenterName._} - #{session.SessionDuration._} mins - #{votesForSession.length} votes\n"
        nOrder = nOrder + 1
      msg.reply result
    )
  .catch (error) ->
    msg.reply JSON.stringify(error)

module.exports = (robot) ->
  robot.respond /votes$/, (msg) ->
    msg.reply "Getting votes for sessions..."
    listVotes(msg)
  robot.respond /test$/, (msg) ->
    msg.reply "Testing..."
    msg.reply getSentence(0)
