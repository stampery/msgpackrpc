msgpack = require 'msgpack'

class MsgpackRPC
  id : 0

  cbs : {}

  methods : {}

  constructor : (@namespace, @sock) ->
    @sock.on 'drain', (h) -> console.log "Draining: #{h}"
    ms = new msgpack.Stream @sock
    ms.addListener 'msg', @_parse.bind this

  _write : (data) ->
    try
      @sock.write data
    catch e
      setTimeout @_write.bind(this, data), 500

  invoke : (method, params, cb) ->
    req = msgpack.pack [0, @id, "#{@namespace}.#{method}", params]
    @cbs[@id++] = cb
    @_write req

  _parse : (packet) ->
    # Method: [type, msgid, method, params]
    if packet[0] is 0
      method = packet[2].replace "#{@namespace}.", ''
      method = @methods[method]
      # Call method, wait for output and reply with it
      method packet[3], (err, res) =>
        if err
          res = msgpack.pack [1, packet[1], 1, err]
        else
          res = msgpack.pack [1, packet[1], 0, res]
        @_write res

    # Response: [type, msgid, error, result]
    else if packet[0] is 1
      # Call the adecuate callback and delete it
      @cbs[packet[1]](packet[2], packet[3])
      delete @cbs[packet[1]]

module.exports = MsgpackRPC
