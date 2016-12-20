//////////////////
// Requirements //
//////////////////
var express = require('express');
var path = require('path');

var routes = require('./routes/index');

var app = express();

///////////
// Setup //
///////////

// View engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

// Express setup
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, '/node_modules/boostrap/dist/js')));
app.use(express.static(path.join(__dirname, '/node_modules/boostrap/dist/css')));

// Security - CORS
app.use(function(req, res, next) {
	res.header('Access-Control-Allow-Origin', '*');
	res.header('Access-Control-Allow-Headers', 'x-access-token');
	next();
});

////////////
// Routes //
////////////

app.use('/', routes);

////////////////////
// Error handlers //
////////////////////

// Catch 404 and forward to error handler
app.use(function(req, res, next) {
	var err = new Error('Not Found');
	err.status = 404;
	next(err);
});

// Production error handler
// No stacktraces leaked to user
app.use(function(err, req, res, next) {
	res.status(err.status || 500);
	res.render('error', {
		message: err.message,
		error: err, // Change to {} to remove stacktraces
		title: 'error'
	});
});

module.exports = app;
