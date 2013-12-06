// Generated by CoffeeScript 1.6.3
(function() {
  var clrs, context, error, factorSet, fnode, stage,
    _this = this;

  stage = new Kinetic.Stage({
    container: 'container',
    width: 900,
    height: 800
  });

  context = new Psy.KineticContext(stage);

  clrs = ["red", "orange", "purple", "brown", "black", "darkblue", "lightblue", "yellow", "pink", "darkgreen", "lightgreen"];

  factorSet = {
    probe: {
      levels: ["match", "mismatch"]
    },
    load: {
      levels: [1, 2, 3]
    }
  };

  this.coordSampler = new Psy.GridSampler([2, 3, 4], [2, 3, 4]);

  this.colorSampler = new Psy.ExhaustiveSampler(clrs);

  window.display = {
    Display: {
      Prelude: {
        Instructions: {
          pages: {
            1: {
              MarkDown: "\nWelcome to the Experiment!\n==========================\n\nThis is a test of visual short-term memory.\n\nOn every trial a number of colored squares will be briefly presented on the screen.\nTry to remember their colors. After the set of squares dissappear, a single 'probe'\nsquare will appear at one the locations previously occupied by one of the\nsquares. You will have to decide whether the 'probe' square is the same color as the square\nthat previously occupied the same spatial location.\n\n  * If the probe square is the same color ( a match), press the 'n' key.\n\n  * If the probe square is a different color ( a non match), press the 'm' key.\n\n  * If your response is correct, you will will get a \"Correct!\" message, otherwise you will get an \"Incorrect!\" message.\n"
            }
          }
        }
      },
      Block: {
        Start: function(context) {
          return {
            Text: {
              position: "center",
              content: ["Get Ready!", "Press Space Bar to start"]
            },
            Next: {
              SpaceKey: ""
            }
          };
        },
        End: function(context) {
          return {
            Text: {
              position: "center",
              content: ["End of Block", "Press Space Bar to continue to next block"]
            },
            Next: {
              SpaceKey: ""
            }
          };
        }
      },
      Trial: function(trial) {
        var colors, i, pos, probeColor, probeIndex, probePos, setdiff, _i, _ref, _results;
        pos = coordSampler.take(trial.load);
        colors = colorSampler.take(trial.load);
        probeIndex = Psy.sample((function() {
          _results = [];
          for (var _i = 0, _ref = trial.load; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this), 1);
        probePos = pos[probeIndex];
        if (trial.probe === "match") {
          probeColor = colors[probeIndex];
        } else {
          setdiff = _.difference(clrs, [colors[probeIndex]]);
          probeColor = Psy.sample(setdiff, 1)[0];
        }
        return {
          Events: {
            1: {
              FixationCross: {
                length: 100,
                strokeWidth: 5
              },
              Next: {
                Timeout: {
                  duration: 800
                }
              }
            },
            2: {
              Group: {
                stims: (function() {
                  var _j, _ref1, _results1;
                  _results1 = [];
                  for (i = _j = 0, _ref1 = pos.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
                    _results1.push({
                      Rectangle: {
                        position: pos[i],
                        width: 50,
                        height: 50,
                        fill: colors[i]
                      }
                    });
                  }
                  return _results1;
                })(),
                layout: {
                  Grid: [7, 7]
                }
              },
              Next: {
                Timeout: {
                  duration: 1500
                }
              }
            },
            3: {
              Clear: 0,
              Next: {
                Timeout: {
                  duration: 1500
                }
              }
            },
            4: {
              Group: {
                stims: [
                  {
                    Rectangle: {
                      position: probePos,
                      width: 50,
                      height: 50,
                      fill: probeColor
                    }
                  }
                ],
                layout: {
                  Grid: [7, 7]
                }
              },
              Next: {
                KeyPress: {
                  id: "probeResponse",
                  keys: ['n', 'm'],
                  correct: trial.probe === "match" ? 'n' : 'm'
                }
              }
            }
          },
          Feedback: function(eventStack) {
            var ev;
            ev = eventStack.last();
            return {
              HtmlIcon: {
                glyph: ev.Accuracy === true ? "checkmark" : "frown",
                size: "massive",
                x: "50%",
                y: "50%"
              },
              Next: {
                Timeout: {
                  duration: 1500
                }
              }
            };
          }
        };
      }
    }
  };

  fnode = Psy.FactorSetNode.build(factorSet);

  window.trials = fnode.trialList(5, 1);

  window.trials.shuffle();

  window.iter = trials.blockIterator();

  console.log("trials", trials);

  try {
    window.pres = new Psy.Presenter(trials, display.Display, context, context.stimFactory);
    console.log("pres", pres);
    pres.start();
  } catch (_error) {
    error = _error;
    console.log("Caught error", error.name, " ", error.message);
  }

}).call(this);

/*
//@ sourceMappingURL=runner.map
*/
