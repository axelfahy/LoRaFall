'use strict';
var express = require('express');
var router = express.Router();

// Client LoRa
var client = require('../client');

/* GET home page. */
router.get('/', function (req, res) {
    var status = ['Run', 'Walk', 'Fall'];
	res.render('index', {
		title: "IoT",
        //status: status[Math.floor(Math.random() * status.length)]
        //status: client
        status: STATUS
	});
});

module.exports = router;
