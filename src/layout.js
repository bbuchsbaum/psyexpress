// Generated by CoffeeScript 1.6.3
(function() {
  var AbsoluteLayout, GridLayout, Layout, computeGridCells, convertPercentageToFraction, convertToCoordinate, isPercentage, isPositionLabel, positionToCoord, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ = require('lodash');

  isPercentage = function(perc) {
    return _.isString(perc) && perc.slice(-1) === "%";
  };

  isPositionLabel = function(pos) {
    return _.contains(["center", "center-left", "center-right", "top-left", "top-right", "top-center", "bottom-left", "bottom-right", "bottom-center", "left-center", "right-center", "left-top", "right-top", "center-top", "left-bottom", "right-bottom", "center-bottom"], pos);
  };

  positionToCoord = function(pos, offx, offy, width, height, xy) {
    switch (pos) {
      case "center":
        return [offx + width * .5, offy + height * .5];
      case "center-left" || "left-center":
        return [offx + width / 6, offy + height * .5];
      case "center-right" || "right-center":
        return [offx + width * 5 / 6, offy + height * .5];
      case "top-left" || "left-top":
        return [offx + width / 6, offy + height / 6];
      case "top-right" || "right-top":
        return [offx + width * 5 / 6, offy + height / 6];
      case "top-center" || "center-top":
        return [offx + width * .5, offy + height / 6];
      case "bottom-left" || "left-bottom":
        return [offx + width / 6, offy + height * 5 / 6];
      case "bottom-right" || "right-bottom":
        return [offx + width * 5 / 6, offy + height * 5 / 6];
      case "bottom-center" || "center-bottom":
        return [offx + width * .5, offy + height * 5 / 6];
      default:
        return xy;
    }
  };

  convertPercentageToFraction = function(perc, dim) {
    var frac;
    frac = parseFloat(perc) / 100;
    frac = Math.min(1, frac);
    frac = Math.max(0, frac);
    return frac * dim;
  };

  convertToCoordinate = function(val, d) {
    var ret;
    console.log("converting to coordinate!!!!!!!!", val);
    if (isPercentage(val)) {
      return val = convertPercentageToFraction(val, d);
    } else if (isPositionLabel(val)) {
      console.log("found a position label:", val);
      ret = positionToCoord(val, 0, 0, d[0], d[1], [0, 0]);
      console.log("position coordinate", ret);
      return ret;
    } else {
      return Math.min(val, d);
    }
  };

  computeGridCells = function(rows, cols, bounds) {
    var col, row, _i, _results;
    _results = [];
    for (row = _i = 0; 0 <= rows ? _i < rows : _i > rows; row = 0 <= rows ? ++_i : --_i) {
      _results.push((function() {
        var _j, _results1;
        _results1 = [];
        for (col = _j = 0; 0 <= cols ? _j < cols : _j > cols; col = 0 <= cols ? ++_j : --_j) {
          _results1.push({
            x: bounds.x + bounds.width / cols * col,
            y: bounds.y + bounds.height / rows * row,
            width: bounds.width / cols,
            height: bounds.height / rows
          });
        }
        return _results1;
      })());
    }
    return _results;
  };

  exports.Layout = Layout = (function() {
    function Layout() {}

    Layout.prototype.computePosition = function(dim, constraints) {
      throw new Error("unimplimented error");
    };

    return Layout;

  })();

  exports.AbsoluteLayout = AbsoluteLayout = (function(_super) {
    __extends(AbsoluteLayout, _super);

    function AbsoluteLayout() {
      _ref = AbsoluteLayout.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    AbsoluteLayout.prototype.computePosition = function(dim, constraints) {
      var x, y;
      console.log("dim", dim);
      console.log("constraints", constraints);
      if (_.isArray(constraints)) {
        x = convertToCoordinate(constraints[0], dim[0]);
        y = convertToCoordinate(constraints[1], dim[1]);
        return [x, y];
      } else {
        return convertToCoordinate(constraints, dim);
      }
    };

    return AbsoluteLayout;

  })(Layout);

  exports.GridLayout = GridLayout = (function(_super) {
    __extends(GridLayout, _super);

    function GridLayout(rows, cols, bounds) {
      this.rows = rows;
      this.cols = cols;
      this.bounds = bounds;
      this.ncells = this.rows * this.cols;
      this.cells = this.computeCells();
    }

    GridLayout.prototype.computeCells = function() {
      return computeGridCells(this.rows, this.cols, this.bounds);
    };

    GridLayout.prototype.computePosition = function(dim, constraints) {
      var cell;
      if (dim[0] !== this.bounds.width && dim[1] !== this.bounds.height) {
        this.bounds.width = dim[0];
        this.bounds.height = dim[1];
        this.cells = this.computeCells();
      }
      cell = this.cells[constraints[0]][constraints[1]];
      return [cell.x + cell.width / 2, cell.y + cell.height / 2];
    };

    return GridLayout;

  })(Layout);

  exports.positionToCoord = positionToCoord;

}).call(this);
