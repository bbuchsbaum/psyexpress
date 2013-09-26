// Generated by CoffeeScript 1.4.0
(function() {
  var Arrow, Background, Bacon, Blank, CanvasBorder, Circle, Clear, ClickResponse, FirstResponse, FixationCross, Group, KeypressResponse, KineticContext, KineticStimFactory, MousepressResponse, Picture, Prompt, Psy, Q, Rectangle, Response, Sequence, Sound, SpaceKeyResponse, StartButton, Stimulus, Text, Timeout, TypedResponse, doTimer, getTimestamp, position, x, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Psy = require("./PsyCloud");

  Bacon = require("./lib/Bacon").Bacon;

  _ = require('lodash');

  Q = require("q");

  if (typeof window !== "undefined" && window !== null ? window.performance.now : void 0) {
    console.log("Using high performance timer");
    getTimestamp = function() {
      return window.performance.now();
    };
  } else if (typeof window !== "undefined" && window !== null ? window.performance.webkitNow : void 0) {
    console.log("Using webkit high performance timer");
    getTimestamp = function() {
      return window.performance.webkitNow();
    };
  } else {
    console.log("Using low performance timer");
    getTimestamp = function() {
      return new Date().getTime();
    };
  }

  doTimer = function(length, resolution, oninstance, oncomplete) {
    var count, instance, speed, start, steps;
    instance = function() {
      var diff;
      if (count++ === steps) {
        return oncomplete(steps, count);
      } else {
        oninstance(steps, count);
        diff = (getTimeStamp() - start) - (count * speed);
        return window.setTimeout(instance, speed - diff);
      }
    };
    steps = (length / 100) * (resolution / 10);
    speed = length / steps;
    count = 0;
    start = getTimeStamp();
    return window.setTimeout(instance, speed);
  };

  exports.Response = Response = (function() {

    function Response() {}

    Response.delay = function(ms, func) {
      return setTimeout(func, ms);
    };

    return Response;

  })();

  exports.Timeout = Timeout = (function(_super) {

    __extends(Timeout, _super);

    function Timeout(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        duration: 2000
      });
    }

    Timeout.prototype.activate = function(context) {
      console.log("activating Timeout", this.spec.duration);
      return Q.delay(this.spec.duration);
    };

    return Timeout;

  })(Response);

  exports.Prompt = Prompt = (function(_super) {

    __extends(Prompt, _super);

    function Prompt(spec) {
      this.spec = spec != null ? spec : {};
      this.spec = _.defaults(this.spec, {
        title: "",
        delay: 0,
        defaultValue: ""
      });
    }

    Prompt.prototype.activate = function(context) {
      var deferred, promise,
        _this = this;
      console.log("Prompting: ", this.title);
      deferred = Q.defer();
      promise = Q.delay(this.spec.delay);
      console.log("got promise");
      promise.then(function(f) {
        var result;
        result = window.prompt(_this.spec.title, _this.spec.defaultValue);
        return deferred.resolve(result);
      });
      return deferred.promise;
    };

    return Prompt;

  })(Response);

  exports.TypedResponse = TypedResponse = (function() {

    function TypedResponse(spec) {
      this.spec = spec != null ? spec : {};
      this.spec = _.defaults(this.spec, {
        left: 250,
        top: 250,
        defaultValue: ""
      });
    }

    TypedResponse.prototype.activate = function(context) {
      var cursor, deferred, enterPressed, freeText, keyStream, text, xoffset,
        _this = this;
      deferred = Q.defer();
      enterPressed = false;
      freeText = "____";
      text = new fabric.Text(freeText, {
        top: this.spec.top,
        left: this.spec.left,
        fontSize: 50,
        textAlign: "left"
      });
      context.canvas.add(text);
      xoffset = text.width / 2;
      cursor = new fabric.Line([this.spec.left, this.spec.top + text.height / 2, this.spec.left, this.spec.top - (text.height / 2)]);
      context.canvas.add(cursor);
      keyStream = context.keypressStream();
      keyStream.takeWhile(function(x) {
        return enterPressed === false;
      }).onValue(function(event) {
        var char;
        if (event.keyCode === 13) {
          enterPressed = true;
          return deferred.resolve(freeText);
        } else {
          char = String.fromCharCode(event.keyCode);
          freeText = freeText + char;
          text.setText(freeText);
          text.set({
            "left": _this.spec.left + (text.width / 2 - xoffset)
          });
          console.log(text.width);
          console.log(text.height);
          return context.canvas.renderAll();
        }
      });
      return deferred.promise;
    };

    return TypedResponse;

  })();

  exports.MousepressResponse = MousepressResponse = (function(_super) {

    __extends(MousepressResponse, _super);

    function MousepressResponse() {}

    MousepressResponse.prototype.activate = function(context) {
      var deferred, mouse,
        _this = this;
      deferred = Q.defer();
      mouse = context.mousepressStream();
      mouse.stream.take(1).onValue(function(event) {
        mouse.stop();
        return deferred.resolve(event);
      });
      return deferred.promise;
    };

    return MousepressResponse;

  })(Response);

  exports.KeypressResponse = KeypressResponse = (function(_super) {

    __extends(KeypressResponse, _super);

    function KeypressResponse(spec) {
      this.spec = spec != null ? spec : {};
      this.spec = _.defaults(this.spec, {
        keys: ['n', 'm'],
        correct: ['n'],
        timeout: 3000
      });
    }

    KeypressResponse.prototype.activate = function(context) {
      var deferred, keyStream,
        _this = this;
      deferred = Q.defer();
      keyStream = context.keypressStream();
      keyStream.filter(function(event) {
        var char;
        char = String.fromCharCode(event.keyCode);
        console.log(char);
        console.log(event.keyCode);
        return _.contains(_this.spec.keys, char);
      }).take(1).onValue(function(filtered) {
        var Acc;
        Acc = _.contains(_this.spec.correct, String.fromCharCode(filtered.keyCode));
        console.log("Acc", Acc);
        context.logEvent("$ACC", Acc);
        return deferred.resolve(event);
      });
      return deferred.promise;
    };

    return KeypressResponse;

  })(Response);

  exports.SpaceKeyResponse = SpaceKeyResponse = (function(_super) {

    __extends(SpaceKeyResponse, _super);

    function SpaceKeyResponse(spec) {
      this.spec = spec != null ? spec : {};
    }

    SpaceKeyResponse.prototype.activate = function(context) {
      var deferred, keyStream,
        _this = this;
      deferred = Q.defer();
      keyStream = context.keypressStream();
      keyStream.filter(function(event) {
        var char;
        char = String.fromCharCode(event.keyCode);
        console.log(char);
        console.log(event.keyCode);
        return event.keyCode === 32;
      }).take(1).onValue(function(event) {
        return deferred.resolve(event);
      });
      return deferred.promise;
    };

    return SpaceKeyResponse;

  })(Response);

  exports.FirstResponse = FirstResponse = (function(_super) {

    __extends(FirstResponse, _super);

    function FirstResponse(responses) {
      this.responses = responses;
    }

    FirstResponse.prototype.activate = function(context) {
      var deferred, promises,
        _this = this;
      deferred = Q.defer();
      promises = _.map(this.responses, function(resp) {
        return resp.activate(context).then(function() {
          return deferred.resolve(resp);
        });
      });
      return deferred.promise;
    };

    return FirstResponse;

  })(Response);

  exports.ClickResponse = ClickResponse = (function(_super) {

    __extends(ClickResponse, _super);

    function ClickResponse(id) {
      this.id = id;
    }

    ClickResponse.prototype.activate = function(context) {
      var deferred, element,
        _this = this;
      element = context.stage.get("#" + this.id);
      if (!element) {
        throw "cannot find element with id" + this.id;
      }
      deferred = Q.defer();
      element.on("click", function(ev) {
        return deferred.resolve(ev);
      });
      return deferred.promise;
    };

    return ClickResponse;

  })(Response);

  exports.Stimulus = Stimulus = (function() {

    Stimulus.prototype.spec = {};

    Stimulus.prototype.overlay = false;

    function Stimulus() {}

    Stimulus.prototype.render = function(context, layer) {};

    Stimulus.prototype.stop = function() {};

    Stimulus.prototype.id = function() {
      return this.spec.id || -9999;
    };

    return Stimulus;

  })();

  exports.Sound = Sound = (function() {

    function Sound(url) {
      this.url = url;
      this.sound = new buzz.sound(this.url);
    }

    Sound.prototype.render = function(context) {
      return this.sound.play();
    };

    return Sound;

  })();

  exports.Picture = Picture = (function(_super) {

    __extends(Picture, _super);

    function Picture(spec) {
      var _this = this;
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        url: "http://www.html5canvastutorials.com/demos/assets/yoda.jpg",
        x: 0,
        y: 0
      });
      this.imageObj = new Image();
      this.image = null;
      this.imageObj.onload = function() {
        return _this.image = new Kinetic.Image({
          x: _this.spec.x,
          y: _this.spec.y,
          image: _this.imageObj,
          width: _this.spec.width || _this.imageObj.width,
          height: _this.spec.height || _this.imageObj.height
        });
      };
      this.imageObj.src = this.spec.url;
    }

    Picture.prototype.render = function(context, layer) {
      return layer.add(this.image);
    };

    return Picture;

  })(Stimulus);

  exports.Group = Group = (function(_super) {

    __extends(Group, _super);

    function Group(stims) {
      this.stims = stims;
      this.overlay = true;
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

  exports.Background = Background = (function(_super) {

    __extends(Background, _super);

    function Background(stims, fill) {
      this.stims = stims != null ? stims : [];
      this.fill = fill != null ? fill : "red";
      this.background = new Kinetic.Rect({
        x: 0,
        y: 0,
        width: 0,
        height: 0,
        fill: this.fill
      });
    }

    Background.prototype.render = function(context, layer) {
      var stim, _i, _len, _ref, _results;
      this.background = new Kinetic.Rect({
        x: 0,
        y: 0,
        width: context.width(),
        height: context.height(),
        name: 'background',
        fill: this.fill
      });
      console.log("rendering background");
      layer.add(this.background);
      _ref = this.stims;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        stim = _ref[_i];
        console.log("rendering stim background");
        _results.push(stim.render(context, layer));
      }
      return _results;
    };

    return Background;

  })(Stimulus);

  exports.Sequence = Sequence = (function(_super) {

    __extends(Sequence, _super);

    Sequence.prototype.stopped = false;

    function Sequence(stims, soa, clear) {
      var i;
      this.stims = stims;
      this.soa = soa;
      this.clear = clear != null ? clear : true;
      if (this.soa.length !== this.stims.length) {
        this.soa = Psy.repLen(this.soa, this.stims.length);
      }
      this.onsets = (function() {
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 0, _ref = this.soa.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          _results.push(_.reduce(this.soa.slice(0, +i + 1 || 9e9), function(x, acc) {
            return x + acc;
          }));
        }
        return _results;
      }).call(this);
    }

    Sequence.prototype.render = function(context, layer) {
      var _i, _ref, _results,
        _this = this;
      return _.forEach((function() {
        _results = [];
        for (var _i = 0, _ref = this.stims.length; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this), function(i) {
        var ev, stim;
        ev = new Timeout({
          duration: _this.onsets[i]
        });
        stim = _this.stims[i];
        return ev.activate(context).then(function() {
          if (!_this.stopped) {
            if (_this.clear) {
              context.clearContent();
            }
            console.log("drawing stim");
            stim.render(context, layer);
            return context.draw();
          }
        });
      });
    };

    Sequence.prototype.stop = function() {
      console.log("stopping Sequence!");
      return this.stopped = true;
    };

    return Sequence;

  })(Stimulus);

  exports.Blank = Blank = (function(_super) {

    __extends(Blank, _super);

    function Blank(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        fill: "white"
      });
    }

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

  exports.Clear = Clear = (function(_super) {

    __extends(Clear, _super);

    function Clear(spec) {
      this.spec = spec != null ? spec : {};
    }

    Clear.prototype.render = function(context, layer) {
      return context.clearContent(true);
    };

    return Clear;

  })(Stimulus);

  exports.Arrow = Arrow = (function(_super) {

    __extends(Arrow, _super);

    function Arrow(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        x: 100,
        y: 100,
        length: 100,
        angle: 0,
        thickness: 40,
        fill: "red",
        arrowSize: 50
      });
    }

    Arrow.prototype.render = function(context, layer) {
      var group, rect, triangle, _this;
      rect = new Kinetic.Rect({
        x: this.spec.x,
        y: this.spec.y,
        width: this.spec.length,
        height: this.spec.thickness,
        fill: this.spec.fill
      });
      _this = this;
      triangle = new Kinetic.Shape({
        drawFunc: function(cx) {
          cx.beginPath();
          cx.moveTo(_this.spec.x + _this.spec.length, _this.spec.y - _this.spec.arrowSize / 2.0);
          cx.lineTo(_this.spec.x + _this.spec.length + _this.spec.arrowSize, _this.spec.y + _this.spec.thickness / 2.0);
          cx.lineTo(_this.spec.x + _this.spec.length, _this.spec.y + _this.spec.thickness + _this.spec.arrowSize / 2.0);
          cx.closePath();
          return cx.fillStrokeShape(this);
        },
        fill: _this.spec.fill
      });
      group = new Kinetic.Group();
      group.add(rect);
      group.add(triangle);
      console.log("Width", group.getWidth());
      group.setOffset((_this.spec.length + _this.spec.arrowSize) / 2.0, _this.spec.thickness / 2.0);
      group.setRotationDeg(_this.spec.angle);
      return layer.add(group);
    };

    return Arrow;

  })(Stimulus);

  exports.Rectangle = Rectangle = (function(_super) {

    __extends(Rectangle, _super);

    function Rectangle(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        fill: 'red'
      });
      this.spec = _.omit(this.spec, function(value, key) {
        return !value;
      });
    }

    Rectangle.prototype.render = function(context, layer) {
      var rect;
      rect = new Kinetic.Rect({
        x: this.spec.x,
        y: this.spec.y,
        width: this.spec.width,
        height: this.spec.height,
        fill: this.spec.fill,
        stroke: this.spec.stroke,
        strokeWidth: this.spec.strokeWidth
      });
      return layer.add(rect);
    };

    return Rectangle;

  })(Stimulus);

  exports.Circle = Circle = (function(_super) {

    __extends(Circle, _super);

    function Circle(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        x: 100,
        y: 100,
        radius: 50,
        fill: 'red'
      });
    }

    Circle.prototype.render = function(context, layer) {
      var circ;
      circ = new Kinetic.Circle({
        x: this.spec.x,
        y: this.spec.y,
        radius: this.spec.radius,
        fill: this.spec.fill,
        stroke: this.spec.stroke,
        strokeWidth: this.spec.strokeWidth
      });
      return layer.add(circ);
    };

    return Circle;

  })(Stimulus);

  exports.FixationCross = FixationCross = (function(_super) {

    __extends(FixationCross, _super);

    function FixationCross(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        strokeWidth: 8,
        length: 150,
        fill: 'black'
      });
    }

    FixationCross.prototype.render = function(context, layer) {
      var group, horz, vert, x, y;
      x = context.width() / 2;
      y = context.height() / 2;
      horz = new Kinetic.Rect({
        x: x - this.spec.length / 2,
        y: y,
        width: this.spec.length,
        height: this.spec.strokeWidth,
        fill: this.spec.fill
      });
      vert = new Kinetic.Rect({
        x: x - this.spec.strokeWidth / 2,
        y: y - this.spec.length / 2 + this.spec.strokeWidth / 2,
        width: this.spec.strokeWidth,
        height: this.spec.length,
        fill: this.spec.fill
      });
      group = new Kinetic.Group();
      group.add(horz);
      group.add(vert);
      return layer.add(group);
    };

    return FixationCross;

  })(Stimulus);

  exports.CanvasBorder = CanvasBorder = (function(_super) {

    __extends(CanvasBorder, _super);

    function CanvasBorder(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        strokeWidth: 5,
        stroke: "black"
      });
    }

    CanvasBorder.prototype.render = function(context, layer) {
      var border;
      border = new Kinetic.Rect({
        x: 0,
        y: 0,
        width: context.width(),
        height: context.height(),
        strokeWidth: this.spec.strokeWidth,
        stroke: this.spec.stroke
      });
      return layer.add(border);
    };

    return CanvasBorder;

  })(Stimulus);

  exports.StartButton = StartButton = (function(_super) {

    __extends(StartButton, _super);

    function StartButton(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        width: 150,
        height: 75
      });
    }

    StartButton.prototype.render = function(context, layer) {
      var button, group, text, xcenter, ycenter;
      xcenter = context.width() / 2;
      ycenter = context.height() / 2;
      group = new Kinetic.Group({
        id: this.spec.id
      });
      text = new Kinetic.Text({
        text: "Start",
        x: xcenter - this.spec.width / 2,
        y: ycenter - this.spec.height / 2,
        width: this.spec.width,
        height: this.spec.height,
        fontSize: 30,
        fill: "white",
        fontFamily: "Arial",
        align: "center",
        padding: 20
      });
      button = new Kinetic.Rect({
        x: xcenter - this.spec.width / 2,
        y: ycenter - text.getHeight() / 2,
        width: this.spec.width,
        height: text.getHeight(),
        fill: "black",
        cornerRadius: 10,
        stroke: "LightSteelBlue",
        strokeWidth: 5
      });
      group.add(button);
      group.add(text);
      return layer.add(group);
    };

    return StartButton;

  })(Stimulus);

  position = function(pos, offx, offy, width, height, xy) {
    switch (pos) {
      case "center":
        return [offx + width * .5, offy + height * .5];
      case "center-left":
        return [offx + width * 1 / 6, offy + height * .5];
      case "center-right":
        return [offx + width * 5 / 6, offy + height * .5];
      case "top-left":
        return [offx + width * 1 / 6, offy + height * 1 / 6];
      case "top-right":
        return [offx + width * 5 / 6, offy + height * 1 / 6];
      case "top-center":
        return [offx + width * .5, offy + height * 1 / 6];
      case "bottom-left":
        return [offx + width * 1 / 6, offy + height * 5 / 6];
      case "bottom-right":
        return [offx + width * 5 / 6, offy + height * 5 / 6];
      case "bottom-center":
        return [offx + width * .5, offy + height * 5 / 6];
      default:
        return xy;
    }
  };

  exports.Text = Text = (function(_super) {

    __extends(Text, _super);

    function Text(spec) {
      if (spec == null) {
        spec = {};
      }
      this.spec = _.defaults(spec, {
        content: "Text",
        x: 100,
        y: 100,
        fill: "black",
        fontSize: 50,
        fontFamily: "Arial",
        lineHeight: 1,
        textAlign: "center",
        position: null
      });
    }

    Text.prototype.render = function(context, layer) {
      var text, xy;
      text = new Kinetic.Text({
        x: this.spec.x,
        y: this.spec.y,
        text: this.spec.content,
        fontSize: this.spec.fontSize,
        fontFamily: this.spec.fontFamily,
        fill: this.spec.fill,
        listening: false
      });
      if (this.spec.position) {
        xy = position(this.spec.position, -text.getWidth() / 2, -text.getHeight() / 2, context.width(), context.height(), [this.spec.x, this.spec.y]);
        text.setPosition({
          x: xy[0],
          y: xy[1]
        });
      }
      return layer.add(text);
    };

    return Text;

  })(Stimulus);

  exports.KineticContext = KineticContext = (function(_super) {

    __extends(KineticContext, _super);

    function KineticContext(stage) {
      this.stage = stage;
      this.contentLayer = new Kinetic.Layer({
        clearBeforeDraw: true
      });
      this.backgroundLayer = new Kinetic.Layer({
        clearBeforeDraw: true
      });
      this.background = new Background([], {
        fill: "white"
      });
      this.stage.add(this.backgroundLayer);
      this.stage.add(this.contentLayer);
      this.backgroundLayer.on("click", function() {
        return console.log("background layer click");
      });
      this.stage.on("mousedown", function() {
        return console.log("stage mouse down");
      });
      this.stage.getContent().addEventListener('mousedown', function() {
        return console.log("stage dom click");
      });
    }

    KineticContext.prototype.setBackground = function(newBackground) {
      this.background = newBackground;
      this.backgroundLayer.removeChildren();
      return this.background.render(this, this.backgroundLayer);
    };

    KineticContext.prototype.drawBackground = function() {
      return this.backgroundLayer.draw();
    };

    KineticContext.prototype.clearBackground = function() {
      return this.backgroundLayer.removeChildren();
    };

    KineticContext.prototype.clearContent = function(draw) {
      if (draw == null) {
        draw = false;
      }
      this.contentLayer.removeChildren();
      if (draw) {
        return this.draw();
      }
    };

    KineticContext.prototype.draw = function() {
      this.backgroundLayer.draw();
      return this.contentLayer.draw();
    };

    KineticContext.prototype.width = function() {
      return this.stage.getWidth();
    };

    KineticContext.prototype.height = function() {
      return this.stage.getHeight();
    };

    KineticContext.prototype.offsetX = function() {
      return this.stage.getOffsetX();
    };

    KineticContext.prototype.offsetY = function() {
      return this.stage.getOffsetY();
    };

    KineticContext.prototype.keydownStream = function() {
      return Bacon.fromEventTarget(window, "keydown");
    };

    KineticContext.prototype.keypressStream = function() {
      return Bacon.fromEventTarget(window, "keypress");
    };

    KineticContext.prototype.mousepressStream = function() {
      var MouseBus;
      MouseBus = (function() {

        function MouseBus() {
          var _this = this;
          this.stream = new Bacon.Bus();
          this.handler = function(x) {
            return _this.stream.push(x);
          };
          this.stage.on("mousedown", this.handler);
        }

        MouseBus.prototype.stop = function() {
          this.stage.off("mousedown", this.handler);
          return this.stream.end();
        };

        return MouseBus;

      })();
      return new MouseBus();
    };

    return KineticContext;

  })(Psy.ExperimentContext);

  exports.KineticStimFactory = KineticStimFactory = (function(_super) {

    __extends(KineticStimFactory, _super);

    function KineticStimFactory() {
      return KineticStimFactory.__super__.constructor.apply(this, arguments);
    }

    KineticStimFactory.prototype.makeStimulus = function(name, params) {
      switch (name) {
        case "FixationCross":
          return new FixationCross(params);
        case "Text":
          return new Text(params);
        default:
          throw "No Stimulus type of name " + name;
      }
    };

    KineticStimFactory.prototype.makeResponse = function(name, params) {
      switch (name) {
        case "KeyPressed":
          return new KeypressResponse(params);
        case "Timeout":
          return new Timeout(params);
        default:
          throw "No Response type of name " + name;
      }
    };

    KineticStimFactory.prototype.makeEvent = function(stim, response) {
      return new Psy.Event(stim, response);
    };

    return KineticStimFactory;

  })(Psy.StimFactory);

  x = new Sequence(['a', 'b', 'c'], [0, 1000, 1500]);

}).call(this);
