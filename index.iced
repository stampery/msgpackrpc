msgpack = require 'msgpack'

class MsgpackRPC
  id : 0

  cbs : {}

  methods : {}

  constructor : (@namespace, @sock) ->
    @sock.on 'data', @_parse.bind this

  _write : (data) ->
    try
      @sock.write data
    catch e
      setTimeout @_write.bind(this, data), 500

  invoke : (method, params, cb) ->
    req = msgpack.pack [0, @id, "#{@namespace}.#{method}", params]
    @_write req
    @cbs[@id++] = cb

  _parse : (data) ->
    parsed = msgpack.unpack data
    # Method: [type, msgid, method, params]
    if parsed[0] is 0
      method = parsed[2].replace "#{@namespace}.", ''
      method = @methods[method]
      # Call method, wait for output and reply with it
      method parsed[3], (err, res, end) =>
        res = msgpack.pack [1, parsed[1], err, res, end]
        @_write res
    # Response: [type, msgid, error, result]
    else if parsed[0] is 1
      # Call the adecuate callback
      isend = (parsed[4] is true)
      console.log @cbs
      console.log parsed[1]
      @cbs[parsed[1]](parsed[2], parsed[3], isend)
      delete @cbs[parsed[1]] if isend

module.exports = MsgpackRPC
