// Generated by CoffeeScript 1.6.3
(function() {
  var getTimestamp, _, _ref, _ref1;

  _ = require('lodash');

  if (typeof window !== "undefined" && window !== null ? (_ref = window.performance) != null ? _ref.now : void 0 : void 0) {
    getTimestamp = function() {
      return window.performance.now();
    };
  } else if (typeof window !== "undefined" && window !== null ? (_ref1 = window.performance) != null ? _ref1.webkitNow : void 0 : void 0) {
    getTimestamp = function() {
      return window.performance.webkitNow();
    };
  } else {
    getTimestamp = function() {
      return new Date().getTime();
    };
  }

  exports.getTimeStamp = getTimestamp;

  this.browserBackDisabled = false;

  exports.disableBrowserBack = function() {
    var rx;
    if (!this.browserBackDisabled) {
      rx = /INPUT|SELECT|TEXTAREA/i;
      this.browserBackDisabled = true;
      return $(document).bind("keydown keypress", function(e) {
        if (e.which === 8) {
          if (!rx.test(e.target.tagName) || e.target.disabled || e.target.readOnly) {
            return e.preventDefault();
          }
        }
      });
    }
  };

  exports.module = function(name) {
    return global[name] = global[name] || {};
  };

  exports.asArray = function(value) {
    if (_.isArray(value)) {
      return value;
    } else if (_.isNumber(value) || _.isBoolean(value)) {
      return [value];
    } else {
      return _.toArray(value);
    }
  };

  exports.permute = function(input) {
    var main, permArr, usedChars;
    permArr = [];
    usedChars = [];
    exports.main = main = function(input) {
      var ch, i, _i, _ref2;
      for (i = _i = 0, _ref2 = input.length; 0 <= _ref2 ? _i < _ref2 : _i > _ref2; i = 0 <= _ref2 ? ++_i : --_i) {
        ch = input.splice(i, 1)[0];
        usedChars.push(ch);
        if (input.length === 0) {
          permArr.push(usedChars.slice());
        }
        main(input);
        input.splice(i, 0, ch);
        usedChars.pop();
      }
      return permArr;
    };
    return main(input);
  };

  exports.rep = function(vec, times) {
    var el, i, j, out,
      _this = this;
    if (!(times instanceof Array)) {
      times = [times];
    }
    if (times.length !== 1 && vec.length !== times.length) {
      throw "vec.length must equal times.length or times.length must be 1";
    }
    if (vec.length === times.length) {
      out = (function() {
        var _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = vec.length; _i < _len; i = ++_i) {
          el = vec[i];
          _results.push((function() {
            var _j, _ref2, _results1;
            _results1 = [];
            for (j = _j = 1, _ref2 = times[i]; 1 <= _ref2 ? _j <= _ref2 : _j >= _ref2; j = 1 <= _ref2 ? ++_j : --_j) {
              _results1.push(el);
            }
            return _results1;
          })());
        }
        return _results;
      })();
      return _.flatten(out);
    } else {
      out = _.times(times[0], function(n) {
        return vec;
      });
      return _.flatten(out);
    }
  };

  exports.repLen = function(vec, length) {
    var i, _i, _results;
    if (length < 1) {
      throw "repLen: length must be greater than or equal to 1";
    }
    _results = [];
    for (i = _i = 0; 0 <= length ? _i < length : _i > length; i = 0 <= length ? ++_i : --_i) {
      _results.push(vec[i % vec.length]);
    }
    return _results;
  };

  exports.sample = function(elements, n, replace) {
    var i, _i, _results;
    if (replace == null) {
      replace = false;
    }
    if (n > elements.length && !replace) {
      throw "cannot take sample larger than the number of elements when 'replace' argument is false";
    }
    if (!replace) {
      return _.shuffle(elements).slice(0, n);
    } else {
      _results = [];
      for (i = _i = 0; 0 <= n ? _i < n : _i > n; i = 0 <= n ? ++_i : --_i) {
        _results.push(Math.floor(Math.random() * elements.length));
      }
      return _results;
    }
  };

  exports.doTimer = function(length, oncomplete) {
    var instance, start;
    start = getTimestamp();
    instance = function() {
      var diff, half;
      diff = getTimestamp() - start;
      if (diff >= length) {
        return oncomplete(diff);
      } else {
        half = Math.max((length - diff) / 2, 1);
        if (half < 20) {
          half = 1;
        }
        return setTimeout(instance, half);
      }
    };
    return setTimeout(instance, 1);
  };

}).call(this);

/*
//@ sourceMappingURL=utils.map
*/
