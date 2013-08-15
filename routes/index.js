
/*
 * GET home page.
 */


exports.index = function(req, res){
    res.render('index', {
        scripts: ['/javascripts/hello.js', '/javascripts/PsyTools.js'],
        title: 'Express'
    });
};