{randomString} = require './utils'
config = require './config'
express = require 'express'
Room = require './room'
storage = require './storage'
path = require 'path'
rooms = {}

app = express()
http = require('http').Server app
io = require('socket.io')(http)

app.set 'views', __dirname
app.set 'view engine', 'jade'
app.use express.static(path.join(__dirname, 'statics'))

app.get '/', (req, res) ->
  res.redirect "/#{randomString(10)}"

app.get '/:room_id', (req, res, next) ->
  {room_id} = req.params

  unless rooms[room_id]
    rooms[room_id] = new Room(room_id, io)

  storage.get(room_id).then (base_data) ->
    res.render 'room',
      room_id: room_id
      base_data: base_data

http.listen config.web.port, ->
  console.info 'markpad is running ...'
