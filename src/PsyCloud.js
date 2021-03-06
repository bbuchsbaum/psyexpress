// Generated by CoffeeScript 1.6.3
(function() {
  var Background, Bacon, Block, BlockSeq, DataTable, Event, EventData, EventDataLog, Experiment, ExperimentContext, ExperimentState, KineticContext, KineticStimFactory, MockStimFactory, Prelude, Presenter, Q, RunnableNode, StimFactory, TAFFY, Trial, buildEvent, buildPrelude, buildResponse, buildStimulus, buildTrial, des, utils, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ = require('lodash');

  Q = require("q");

  TAFFY = require("taffydb").taffy;

  utils = require("./utils");

  DataTable = require("./datatable").DataTable;

  Bacon = require("./lib/Bacon").Bacon;

  KineticStimFactory = require("./elements").KineticStimFactory;

  Background = require("./components/canvas/background").Background;

  exports.EventData = EventData = (function() {
    function EventData(name, id, data) {
      this.name = name;
      this.id = id;
      this.data = data;
    }

    return EventData;

  })();

  exports.EventDataLog = EventDataLog = (function() {
    function EventDataLog() {
      this.eventStack = [];
    }

    EventDataLog.prototype.push = function(ev) {
      return this.eventStack.push(ev);
    };

    EventDataLog.prototype.last = function() {
      if (this.eventStack.length < 1) {
        throw "EventLog is Empty, canot access last element";
      }
      return this.eventStack[this.eventStack.length - 1].data;
    };

    EventDataLog.prototype.findAll = function(id) {
      return _.filter(this.eventStack, function(ev) {
        return ev.id === id;
      });
    };

    EventDataLog.prototype.findLast = function(id) {
      var i, len, _i;
      len = this.eventStack.length - 1;
      for (i = _i = len; len <= 0 ? _i <= 0 : _i >= 0; i = len <= 0 ? ++_i : --_i) {
        if (this.eventStack[i].id === id) {
          return this.eventStack[i];
        }
      }
    };

    return EventDataLog;

  })();

  exports.StimFactory = StimFactory = (function() {
    function StimFactory() {}

    StimFactory.prototype.buildStimulus = function(spec, context) {
      var params, stimType;
      stimType = _.keys(spec)[0];
      params = _.values(spec)[0];
      return this.makeStimulus(stimType, params, context);
    };

    StimFactory.prototype.buildResponse = function(spec, context) {
      var params, responseType;
      responseType = _.keys(spec)[0];
      params = _.values(spec)[0];
      return this.makeResponse(responseType, params, context);
    };

    StimFactory.prototype.buildEvent = function(spec, context) {
      var response, responseSpec, stim, stimSpec;
      stimSpec = _.omit(spec, "Next");
      responseSpec = _.pick(spec, "Next");
      stim = this.buildStimulus(stimSpec, context);
      response = this.buildResponse(responseSpec.Next, context);
      return this.makeEvent(stim, response, context);
    };

    StimFactory.prototype.makeStimulus = function(name, params, context) {
      throw "unimplemented";
    };

    StimFactory.prototype.makeResponse = function(name, params, context) {
      throw "unimplemented";
    };

    StimFactory.prototype.makeEvent = function(stim, response, context) {
      throw "unimplemented";
    };

    return StimFactory;

  })();

  exports.MockStimFactory = MockStimFactory = (function(_super) {
    __extends(MockStimFactory, _super);

    function MockStimFactory() {
      _ref = MockStimFactory.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    MockStimFactory.prototype.makeStimulus = function(name, params, context) {
      var ret;
      ret = {};
      ret[name] = params;
      return ret;
    };

    MockStimFactory.prototype.makeResponse = function(name, params, context) {
      var ret;
      ret = {};
      ret[name] = params;
      return ret;
    };

    MockStimFactory.prototype.makeEvent = function(stim, response, context) {
      return [stim, response];
    };

    return MockStimFactory;

  })(StimFactory);

  exports.RunnableNode = RunnableNode = (function() {
    function RunnableNode(children) {
      this.children = children;
    }

    RunnableNode.functionList = function(nodes, context, callback) {
      var _this = this;
      return _.map(nodes, function(node) {
        return function() {
          if (callback != null) {
            callback(node);
          }
          return node.start(context);
        };
      });
    };

    RunnableNode.prototype.before = function(context) {
      return function() {
        return 0;
      };
    };

    RunnableNode.prototype.after = function(context) {
      return function() {
        return 0;
      };
    };

    RunnableNode.chainFunctions = function(funArray) {
      var fun, result, _i, _len;
      result = Q.resolve(0);
      for (_i = 0, _len = funArray.length; _i < _len; _i++) {
        fun = funArray[_i];
        result = result.then(fun, function(err) {
          console.log("caught error", err);
          throw new Error("Error during execution: ", err);
        });
      }
      return result;
    };

    RunnableNode.prototype.numChildren = function() {
      return this.children.length;
    };

    RunnableNode.prototype.length = function() {
      return this.children.length;
    };

    RunnableNode.prototype.start = function(context) {
      var farray;
      farray = RunnableNode.functionList(this.children, context, function(node) {
        return console.log("callback", node);
      });
      return RunnableNode.chainFunctions(_.flatten([this.before(context), farray, this.after(context)]));
    };

    RunnableNode.prototype.stop = function(context) {};

    return RunnableNode;

  })();

  exports.Event = Event = (function(_super) {
    __extends(Event, _super);

    function Event(stimulus, response) {
      this.stimulus = stimulus;
      this.response = response;
      Event.__super__.constructor.call(this, [this.response]);
    }

    Event.prototype.stop = function(context) {
      this.stimulus.stop(context);
      return this.response.stop(context);
    };

    Event.prototype.before = function(context) {
      var _this = this;
      return function() {
        var self;
        self = _this;
        if (!context.exState.inPrelude) {
          context.updateState(function() {
            return context.exState.nextEvent(self);
          });
        }
        if (!_this.stimulus.overlay) {
          context.clearContent();
        }
        _this.stimulus.render(context, context.contentLayer);
        return context.draw();
      };
    };

    Event.prototype.after = function(context) {
      var _this = this;
      return function() {
        return _this.stimulus.stop(context);
      };
    };

    Event.prototype.start = function(context) {
      console.log("starting event", this.stimulus.name);
      return Event.__super__.start.call(this, context);
    };

    return Event;

  })(RunnableNode);

  exports.Trial = Trial = (function(_super) {
    __extends(Trial, _super);

    function Trial(events, record, feedback, background) {
      if (events == null) {
        events = [];
      }
      this.record = record != null ? record : {};
      this.feedback = feedback;
      this.background = background;
      Trial.__super__.constructor.call(this, events);
    }

    Trial.prototype.numEvents = function() {
      return this.children.length;
    };

    Trial.prototype.push = function(event) {
      return this.children.push(event);
    };

    Trial.prototype.before = function(context) {
      var _this = this;
      return function() {
        var self;
        self = _this;
        context.updateState(function() {
          return context.exState.nextTrial(self);
        });
        context.clearBackground();
        if (_this.background != null) {
          context.setBackground(_this.background);
          return context.drawBackground();
        }
      };
    };

    Trial.prototype.after = function(context, callback) {
      var _this = this;
      return function() {
        var event, spec;
        if (_this.feedback != null) {
          console.log("last event ", context.eventDB().last());
          spec = _this.feedback(context.eventDB);
          console.log("spec is", spec);
          event = context.stimFactory.buildEvent(spec, context);
          return event.start(context).then(function() {
            if (callback != null) {
              return callback();
            }
          });
        } else {
          return Q.fcall(function() {
            if (callback != null) {
              return callback();
            }
          });
        }
      };
    };

    Trial.prototype.start = function(context, callback) {
      var farray;
      farray = RunnableNode.functionList(this.children, context, function(event) {
        return console.log("event callback", event);
      });
      return RunnableNode.chainFunctions(_.flatten([this.before(context), farray, this.after(context, callback)]));
    };

    Trial.prototype.stop = function(context) {};

    return Trial;

  })(RunnableNode);

  exports.Block = Block = (function(_super) {
    __extends(Block, _super);

    function Block(children, blockSpec) {
      this.blockSpec = blockSpec;
      Block.__super__.constructor.call(this, children);
    }

    Block.prototype.showEvent = function(spec, context) {
      var event;
      event = buildEvent(spec, context);
      return event.start(context);
    };

    Block.prototype.before = function(context) {
      var self,
        _this = this;
      self = this;
      return function() {
        var spec;
        context.updateState(function() {
          return context.exState.nextBlock(self);
        });
        if ((_this.blockSpec != null) && _this.blockSpec.Start) {
          spec = _this.blockSpec.Start(context);
          return _this.showEvent(spec, context);
        } else {
          return Q.fcall(0);
        }
      };
    };

    Block.prototype.after = function(context) {
      var _this = this;
      return function() {
        var spec;
        if ((_this.blockSpec != null) && _this.blockSpec.End) {
          spec = _this.blockSpec.End(context);
          return _this.showEvent(spec, context);
        } else {
          return Q.fcall(0);
        }
      };
    };

    return Block;

  })(RunnableNode);

  exports.BlockSeq = BlockSeq = (function(_super) {
    __extends(BlockSeq, _super);

    function BlockSeq(children) {
      BlockSeq.__super__.constructor.call(this, children);
    }

    return BlockSeq;

  })(RunnableNode);

  exports.Prelude = Prelude = (function(_super) {
    __extends(Prelude, _super);

    function Prelude(children) {
      Prelude.__super__.constructor.call(this, children);
    }

    Prelude.prototype.before = function(context) {
      var _this = this;
      return function() {
        return context.updateState(function() {
          console.log("setting in prelude!");
          console.log("exState is", context.exState);
          return context.exState.insidePrelude();
        });
      };
    };

    Prelude.prototype.after = function(context) {
      var _this = this;
      return function() {
        return context.updateState(function() {
          return context.exState.outsidePrelude();
        });
      };
    };

    return Prelude;

  })(RunnableNode);

  exports.ExperimentState = ExperimentState = (function() {
    function ExperimentState() {
      this.inPrelude = false;
      this.trial = {};
      this.block = {};
      this.event = {};
      this.blockNumber = 0;
      this.trialNumber = 0;
      this.eventNumber = 0;
      this.stimulus = {};
      this.response = {};
    }

    ExperimentState.prototype.insidePrelude = function() {
      var ret;
      ret = $.extend({}, this);
      ret.inPrelude = true;
      return ret;
    };

    ExperimentState.prototype.outsidePrelude = function() {
      var ret;
      ret = $.extend({}, this);
      ret.inPrelude = false;
      return ret;
    };

    ExperimentState.prototype.nextBlock = function(block) {
      var ret;
      ret = $.extend({}, this);
      ret.blockNumber = this.blockNumber + 1;
      ret.block = block;
      return ret;
    };

    ExperimentState.prototype.nextTrial = function(trial) {
      var ret;
      ret = $.extend({}, this);
      ret.trial = trial;
      ret.trialNumber = this.trialNumber + 1;
      return ret;
    };

    ExperimentState.prototype.nextEvent = function(event) {
      var ret;
      console.log("next Event");
      ret = $.extend({}, this);
      ret.event = event;
      ret.eventNumber = this.eventNumber + 1;
      return ret;
    };

    ExperimentState.prototype.toRecord = function() {
      var key, ret, value, _ref1, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      ret = {
        $blockNumber: this.blockNumber,
        $trialNumber: this.trialNumber,
        $eventNumber: this.eventNumber,
        $stimulus: (_ref1 = this.event) != null ? (_ref2 = _ref1.stimulus) != null ? (_ref3 = _ref2.constructor) != null ? _ref3.name : void 0 : void 0 : void 0,
        $response: (_ref4 = this.event) != null ? (_ref5 = _ref4.response) != null ? (_ref6 = _ref5.constructor) != null ? _ref6.name : void 0 : void 0 : void 0,
        $stimulusID: (_ref7 = this.event) != null ? (_ref8 = _ref7.stimulus) != null ? _ref8.id : void 0 : void 0,
        $responseID: (_ref9 = this.event) != null ? (_ref10 = _ref9.response) != null ? _ref10.id : void 0 : void 0
      };
      if (!_.isEmpty(this.trial) && (this.trial.record != null)) {
        _ref11 = this.trial.record;
        for (key in _ref11) {
          value = _ref11[key];
          ret[key] = value;
        }
      }
      return ret;
    };

    return ExperimentState;

  })();

  exports.ExperimentContext = ExperimentContext = (function() {
    function ExperimentContext(stimFactory) {
      this.stimFactory = stimFactory;
      this.eventDB = TAFFY({});
      this.exState = new ExperimentState();
      this.eventData = new EventDataLog();
      this.log = [];
      this.trialNumber = 0;
      this.currentTrial = new Trial([], {});
    }

    ExperimentContext.prototype.updateState = function(fun) {
      this.exState = fun(this.exState);
      console.log("record is", this.exState.toRecord());
      return this.exState;
    };

    ExperimentContext.prototype.pushData = function(data, withState) {
      var record;
      if (withState == null) {
        withState = true;
      }
      if (withState) {
        record = _.extend(this.exState.toRecord(), data);
      } else {
        record = data;
      }
      this.eventDB.insert(record);
      return console.log("db is now", this.eventDB().get());
    };

    ExperimentContext.prototype.logEvent = function(key, value) {
      var record;
      record = _.clone(this.currentTrial.record);
      record[key] = value;
      this.log.push(record);
      return console.log(this.log);
    };

    ExperimentContext.prototype.showEvent = function(event) {
      return event.start(this);
    };

    ExperimentContext.prototype.start = function(blockList) {
      var error, farray;
      try {
        farray = RunnableNode.functionList(blockList, this, function(block) {
          return console.log("block callback", block);
        });
        return RunnableNode.chainFunctions(farray);
      } catch (_error) {
        error = _error;
        return console.log("caught error:", error);
      }
    };

    ExperimentContext.prototype.clearContent = function() {};

    ExperimentContext.prototype.clearBackground = function() {};

    ExperimentContext.prototype.keydownStream = function() {};

    ExperimentContext.prototype.keypressStream = function() {};

    ExperimentContext.prototype.mousepressStream = function() {};

    ExperimentContext.prototype.draw = function() {};

    ExperimentContext.prototype.insertHTMLDiv = function() {
      $("canvas").css("position", "absolute");
      $("#container").append("<div id=\"htmlcontainer\" class=\"htmllayer\"></div>");
      $("#htmlcontainer").css({
        position: "absolute",
        "z-index": 999,
        outline: "none",
        padding: "5px"
      });
      $("#container").attr("tabindex", 0);
      $("#container").css("outline", "none");
      return $("#container").css("padding", "5px");
    };

    ExperimentContext.prototype.clearHtml = function() {
      $("#htmlcontainer").empty();
      return $("#htmlcontainer").hide();
    };

    ExperimentContext.prototype.appendHtml = function(input) {
      $("#htmlcontainer").addClass("htmllayer");
      $("#htmlcontainer").append(input);
      return $("#htmlcontainer").show();
    };

    ExperimentContext.prototype.hideHtml = function() {
      return $("#htmlcontainer").hide();
    };

    return ExperimentContext;

  })();

  KineticContext = (function(_super) {
    __extends(KineticContext, _super);

    function KineticContext(stage) {
      this.stage = stage;
      KineticContext.__super__.constructor.call(this, new KineticStimFactory());
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
      this.insertHTMLDiv();
    }

    KineticContext.prototype.insertHTMLDiv = function() {
      KineticContext.__super__.insertHTMLDiv.apply(this, arguments);
      return $(".kineticjs-content").css("position", "absolute");
    };

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
      this.clearHtml();
      this.backgroundLayer.draw();
      this.contentLayer.removeChildren();
      if (draw) {
        return this.draw();
      }
    };

    KineticContext.prototype.draw = function() {
      $('#container').focus();
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
      return $("body").asEventStream("keydown");
    };

    KineticContext.prototype.keypressStream = function() {
      return $("body").asEventStream("keypress");
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

  })(exports.ExperimentContext);

  exports.KineticContext = KineticContext;

  buildStimulus = function(spec, context) {
    var params, stimType;
    stimType = _.keys(spec)[0];
    params = _.values(spec)[0];
    return context.stimFactory.makeStimulus(stimType, params, context);
  };

  buildResponse = function(spec, context) {
    var params, responseType;
    responseType = _.keys(spec)[0];
    console.log("response type", responseType);
    params = _.values(spec)[0];
    console.log("params", params);
    return context.stimFactory.makeResponse(responseType, params, context);
  };

  buildEvent = function(spec, context) {
    var response, responseSpec, stim, stimSpec;
    stimSpec = _.omit(spec, "Next");
    responseSpec = _.pick(spec, "Next");
    console.log("stim Spec", stimSpec);
    console.log("response Spec", responseSpec);
    if ((responseSpec == null) || _.isEmpty(responseSpec)) {
      console.log("keys of stimspec", _.keys(stimSpec));
      stim = buildStimulus(stimSpec, context);
      console.log("stim is", stim);
      return context.stimFactory.makeEvent(stim, stim, context);
    } else {
      stim = buildStimulus(stimSpec, context);
      console.log("stim", stim);
      response = buildResponse(responseSpec.Next, context);
      console.log("response", response);
      return context.stimFactory.makeEvent(stim, response, context);
    }
  };

  buildTrial = function(eventSpec, record, context, feedback, background) {
    var events, key, response, responseSpec, stim, stimSpec, value;
    events = (function() {
      var _results;
      _results = [];
      for (key in eventSpec) {
        value = eventSpec[key];
        stimSpec = _.omit(value, "Next");
        responseSpec = _.pick(value, "Next");
        stim = buildStimulus(stimSpec, context);
        response = buildResponse(responseSpec.Next, context);
        _results.push(context.stimFactory.makeEvent(stim, response, context));
      }
      return _results;
    })();
    console.log("building trial with record", record);
    return new Trial(events, record, feedback, background);
  };

  buildPrelude = function(preludeSpec, context) {
    var events, key, spec, value;
    console.log("building prelude");
    events = (function() {
      var _results;
      _results = [];
      for (key in preludeSpec) {
        value = preludeSpec[key];
        spec = {};
        spec[key] = value;
        console.log("prelude spec", spec);
        _results.push(buildEvent(spec, context));
      }
      return _results;
    })();
    console.log("prelude events", events);
    return new Prelude(events);
  };

  exports.Presenter = Presenter = (function() {
    function Presenter(trialList, display, context) {
      this.trialList = trialList;
      this.display = display;
      this.context = context;
      this.trialBuilder = this.display.Trial;
      this.prelude = this.display.Prelude != null ? buildPrelude(this.display.Prelude, this.context) : new Prelude([]);
      console.log("prelude is", this.prelude);
    }

    Presenter.prototype.start = function() {
      var block, record, trialNum, trialSpec, trials,
        _this = this;
      this.blockList = new BlockSeq((function() {
        var _i, _len, _ref1, _results;
        _ref1 = this.trialList.blocks;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          block = _ref1[_i];
          trials = (function() {
            var _j, _ref2, _results1;
            _results1 = [];
            for (trialNum = _j = 0, _ref2 = block.length; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; trialNum = 0 <= _ref2 ? ++_j : --_j) {
              record = _.clone(block[trialNum]);
              trialSpec = this.trialBuilder(record);
              _results1.push(buildTrial(trialSpec.Events, record, this.context, trialSpec.Feedback));
            }
            return _results1;
          }).call(this);
          _results.push(new Block(trials, this.display.Block));
        }
        return _results;
      }).call(this));
      return this.prelude.start(this.context).then(function() {
        return _this.blockList.start(_this.context);
      });
    };

    return Presenter;

  })();

  exports.Experiment = Experiment = (function() {
    function Experiment(designSpec, stimFactory) {
      this.designSpec = designSpec;
      this.stimFactory = stimFactory != null ? stimFactory : new MockStimFactory();
      this.design = new ExpDesign(this.designSpec);
      this.display = this.designSpec.Display;
      this.trialGenerator = this.display.Trial;
    }

    Experiment.prototype.buildStimulus = function(event, context) {
      var params, stimType;
      stimType = _.keys(event)[0];
      params = _.values(event)[0];
      return this.stimFactory.makeStimulus(stimType, params, context);
    };

    Experiment.prototype.buildEvent = function(event, context) {
      var params, responseType;
      responseType = _.keys(event)[0];
      params = _.values(event)[0];
      return this.stimFactory.makeResponse(responseType, params, context);
    };

    Experiment.prototype.buildTrial = function(eventSpec, record, context) {
      var events, key, response, responseSpec, stim, stimSpec, value;
      events = (function() {
        var _results;
        _results = [];
        for (key in eventSpec) {
          value = eventSpec[key];
          stimSpec = _.omit(value, "Next");
          responseSpec = _.pick(value, "Next");
          stim = this.buildStimulus(stimSpec);
          response = this.buildResponse(responseSpec.Next);
          _results.push(this.stimFactory.makeEvent(stim, response));
        }
        return _results;
      }).call(this);
      return new Trial(events, record);
    };

    Experiment.prototype.start = function(context) {
      var i, record, trialList, trialSpec, trials;
      trials = this.design.fullDesign;
      console.log(trials.nrow());
      trialList = (function() {
        var _i, _ref1, _results;
        _results = [];
        for (i = _i = 0, _ref1 = trials.nrow(); 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
          record = trials.record(i);
          record.$trialNumber = i;
          trialSpec = this.trialGenerator(record);
          _results.push(this.buildTrial(trialSpec, record, context));
        }
        return _results;
      }).call(this);
      return context.start(trialList);
    };

    return Experiment;

  })();

  des = {
    Design: {
      Blocks: [
        [
          {
            a: 1,
            b: 2,
            c: 3,
            a: 2,
            b: 3,
            c: 4
          }
        ], [
          {
            a: 5,
            b: 7,
            c: 6,
            a: 5,
            b: 7,
            c: 6
          }
        ]
      ]
    }
  };

  console.log(des.Blocks);

  exports.buildStimulus = buildStimulus;

  exports.buildResponse = buildResponse;

  exports.buildEvent = buildEvent;

  exports.buildTrial = buildTrial;

  exports.buildPrelude = buildPrelude;

}).call(this);
