
var ttn = require('ttn');
var lora_packet = require('lora-packet');


var region = 'eu';
var appId = 'mse-iot-stockstrooper';
var accessKey = 'ttn-account-v2.DolaWum8-C5ipsWb_dcArHfvdpNcCaBq-oGGtuxi5fw';

var client = new ttn.Client(region, appId, accessKey);

// Initialization of connection
client.on('connect', function(connack) {
    console.log('[DEBUG]', 'Connect:', connack);
});

client.on('error', function(err) {
    console.error('[ERROR]', err.message);
});

// Listener for the activation event
client.on('activation', function(deviceId, data) {
    console.log('[INFO] ', 'Activation:', deviceId, data);
});


// Listener for the message event
client.on('message', function(deviceId, data) {
    console.info('[INFO] ', 'Message:', deviceId, JSON.stringify(data, null, 2));
    var buffer = new Buffer(data.payload_raw, 'hex');
    var s_part = buffer.slice(0, buffer.length - 2);
    var n_part = buffer.slice(buffer.length - 2);
    var s = s_part.toString('utf8');
    var n = n_part.readUIntBE(0, 2);
    console.log("Buffer : ", buffer);
    console.log("s_part : ", s_part);
    console.log("n_part : ", n_part);
    console.log("String : ", s);
    console.log("Value : ", n);
});



