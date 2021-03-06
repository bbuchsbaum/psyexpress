// Generated by CoffeeScript 1.6.3
(function() {
  var Arrow, Stimulus, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Stimulus = require("../../stimresp").Stimulus;

  Arrow = (function(_super) {
    __extends(Arrow, _super);

    function Arrow() {
      _ref = Arrow.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Arrow.prototype.defaults = {
      x: 100,
      y: 100,
      length: 100,
      angle: 0,
      thickness: 40,
      fill: "red",
      arrowSize: 50
    };

    Arrow.prototype.render = function(context, layer) {
      var group, rect, triangle, _this;
      rect = new Kinetic.Rect({
        x: 0,
        y: 0,
        width: this.spec.length,
        height: this.spec.thickness,
        fill: this.spec.fill,
        stroke: this.spec.stroke,
        strokeWidth: this.spec.strokeWidth,
        opacity: this.spec.opacity
      });
      _this = this;
      triangle = new Kinetic.Shape({
        drawFunc: function(cx) {
          cx.beginPath();
          cx.moveTo(_this.spec.length, -_this.spec.arrowSize / 2.0);
          cx.lineTo(_this.spec.length + _this.spec.arrowSize, _this.spec.thickness / 2.0);
          cx.lineTo(_this.spec.length, _this.spec.thickness + _this.spec.arrowSize / 2.0);
          cx.closePath();
          return cx.fillStrokeShape(this);
        },
        fill: _this.spec.fill,
        stroke: this.spec.stroke,
        strokeWidth: this.spec.strokeWidth,
        opacity: this.spec.opacity
      });
      group = new Kinetic.Group({
        x: this.spec.x,
        y: this.spec.y,
        rotationDeg: this.spec.angle,
        offset: [0, this.spec.thickness / 2.0]
      });
      group.add(rect);
      group.add(triangle);
      return layer.add(group);
    };

    return Arrow;

  })(Stimulus);

  exports.Arrow = Arrow;

}).call(this);
