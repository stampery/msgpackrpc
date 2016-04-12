// Generated by IcedCoffeeScript 108.0.11
(function() {
  var MsgpackRPC, msgpack;

  msgpack = require('msgpack');

  MsgpackRPC = (function() {
    MsgpackRPC.prototype.id = 0;

    MsgpackRPC.prototype.cbs = [];

    MsgpackRPC.prototype.methods = {};

    function MsgpackRPC(namespace, sock) {
      this.namespace = namespace;
      this.sock = sock;
      this.sock.on('data', this._parse.bind(this));
    }

    MsgpackRPC.prototype._write = function(data) {
      var e;
      try {
        return this.sock.write(data);
      } catch (_error) {
        e = _error;
        return setTimeout(this._write.bind(this, data), 500);
      }
    };

    MsgpackRPC.prototype.invoke = function(method, params, cb) {
      var req;
      req = msgpack.pack([0, this.id++, "" + this.namespace + "." + method, params]);
      this._write(req);
      return this.cbs.push(cb);
    };

    MsgpackRPC.prototype._parse = function(data) {
      var method, parsed;
      parsed = msgpack.unpack(data);
      if (parsed[0] === 0) {
        method = parsed[2].replace("" + this.namespace + ".", '');
        method = this.methods[method];
        return method(parsed[3], (function(_this) {
          return function(err, res, end) {
            res = msgpack.pack([1, parsed[1], err, res, end]);
            return _this._write(res);
          };
        })(this));
      } else if (parsed[0] === 1) {
        this.cbs[parsed[1]](parsed[2], parsed[3]);
        if (parsed[4] === true) {
          return this.cbs[parsed[1]] = null;
        }
      }
    };

    return MsgpackRPC;

  })();

  module.exports = MsgpackRPC;

}).call(this);
