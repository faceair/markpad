Repository = require './repository'
{EventEmitter} = require 'events'
storage = require './storage'
config = require './config'
_ = require 'underscore'

class Members
  constructor: ->
    @members = []

  add: (member) ->
    isIn = _.find @members, (member) ->
      @id is member.id
    unless isIn
      @members.push member

  remove: (member) ->
    @members = _.reject @members, (member) ->
      @id is member.id

  list: ->
    @members

  on: (status, member_id = null) ->
    return _.find @list(), (member) ->
      member.status is status and member.id isnt member_id

class Member
  constructor: (@socket, {@room, @room_id, @repository, @members}) ->
    _.extend @,
      id: @socket.id
      branch: @repository.createBranch(@socket.id)
      status: 'wait'

    @socket.on 'change', @change.bind(@)
    @socket.on 'disconnect', =>
      @members.remove @id

  change: ({h: hash, c: changes}) ->
    @status = 'deal'

    @members.on('deal', @id)

    @branch.commit changes
    storage.set(@room_id, @branch.getHead()).then =>
      @socket.broadcast.emit 'change', changes
      @status = 'wait'

module.exports = class Room
  constructor: (@room_id, io) ->
    @members = new Members()

    @room = io.of "/#{@room_id}"
    storage.get(@room_id).then (base_data) =>

      @repository = new Repository(base_data)
      @room.on 'connection', (socket) =>

        member = new Member socket, @
        @members.add member