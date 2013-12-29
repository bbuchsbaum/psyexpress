// Generated by CoffeeScript 1.6.3
(function() {
  var First, Q, Response,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Q = require("q");

  Response = require("../stimresp").Response;

  First = (function(_super) {
    __extends(First, _super);

    function First(responses) {
      this.responses = responses;
      First.__super__.constructor.call(this, {});
    }

    First.prototype.activate = function(context) {
      var deferred,
        _this = this;
      deferred = Q.defer();
      _.forEach(this.responses, function(resp) {
        return resp.activate(context).then(function() {
          return deferred.resolve(resp);
        });
      });
      return deferred.promise;
    };

    return First;

  })(Response);

  exports.First = First;

}).call(this);
