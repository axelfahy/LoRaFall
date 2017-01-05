var ttn = require('ttn');
var lora_packet = require('lora-packet');

var region = 'eu';
var appId = 'mse-iot-stockstrooper';
var accessKey = 'ttn-account-v2.DolaWum8-C5ipsWb_dcArHfvdpNcCaBq-oGGtuxi5fw';

// Possible state send by the waspmote
var state = ['still', 'walk', 'run', 'fall'];
// Status used in the app
// Dictionary of status with MAC as key and event number as value for each client.
STATUS = {'0b0b448c99d3': 1, '0b0b448c99d2': 2}; // Init values to simulate devices

var client = new ttn.Client(region, appId, accessKey);

// Initialization of connection
client.on('connect', function(connack) {
    console.log('[DEBUG]', 'Connect:', connack);
});

// Error message
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
    // Message format : MAC[14] EVENT_NUMBER[1] (no separation between the two)
    var mac = buffer.slice(0, buffer.length - 1).toString('hex');
    var event_number = buffer.slice(buffer.length - 1).readUIntBE(0, 1);
    console.log("MAC[14]=", mac);
    console.log("Event  =", event_number);
    // Maj page
    // Set the status of the device
    STATUS[mac] = event_number;
    console.log(STATUS);
    // Reload the page
    // TODO Reload the page from here instead of every minute in the html page
});

module.exports = client;
