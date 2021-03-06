// Generated by CoffeeScript 1.6.3
(function() {
  var Blank, Stimulus, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Stimulus = require("../../stimresp").Stimulus;

  Blank = (function(_super) {
    __extends(Blank, _super);

    function Blank() {
      _ref = Blank.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Blank.prototype.defaults = {
      fill: "white"
    };

    Blank.prototype.render = function(context, layer) {
      var blank;
      blank = new Kinetic.Rect({
        x: 0,
        y: 0,
        width: context.width(),
        height: context.height(),
        fill: this.spec.fill
      });
      return layer.add(blank);
    };

    return Blank;

  })(Stimulus);

  exports.Blank = Blank;

}).call(this);
