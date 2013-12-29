// Generated by CoffeeScript 1.6.3
(function() {
  var Group, Stimulus,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Stimulus = require("../stimresp").Stimulus;

  Group = (function(_super) {
    __extends(Group, _super);

    function Group(stims, layout) {
      var stim, _i, _len, _ref;
      this.stims = stims;
      Group.__super__.constructor.call(this, {});
      if (layout) {
        this.layout = layout;
        _ref = this.stims;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          stim = _ref[_i];
          stim.layout = layout;
        }
      }
    }

    Group.prototype.render = function(context, layer) {
      var stim, _i, _len, _ref, _results;
      _ref = this.stims;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        stim = _ref[_i];
        _results.push(stim.render(context, layer));
      }
      return _results;
    };

    return Group;

  })(Stimulus);

  exports.Group = Group;

}).call(this);