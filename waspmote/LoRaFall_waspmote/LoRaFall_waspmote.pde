/*
 *  Waspmote file for LoRaFall project.
 *
 *  Detection of events on a BLE device (rest, walk, run and fall).
 *  Send these events to a LoRa gateway.
 *
 *
 *  Authors:        Axel Fahy & Rudolf Hohn
 *  Version:		1.0
 */

#include <WaspBLE.h>
#include <WaspLoRaWAN.h>

//========================================================================================
//============================== LORA ====================================================
// socket to use
//////////////////////////////////////////////
uint8_t SOCKET_LORA = SOCKET0;
uint8_t SOCKET_BLE = SOCKET1;
//////////////////////////////////////////////

// Device parameters for Back-End registration
////////////////////////////////////////////////////////////
// waspmote-lorafall
/*
char DEVICE_EUI[]  = "00BD58F4DFA67257";
char DEVICE_ADDR[] = "26011B10";
char NWK_SESSION_KEY[] = "10A020678B037A94A1964D0F96575557";
char APP_SESSION_KEY[] = "7A2F4BC2369809728134FCFB8CE7F011";
char DEVICE_ID[] = "776173706d6f74652d6c6f726166616c6c";
*/
// waspmote-lorafall2

char DEVICE_EUI[]  = "003AD7598DF41BB2";
char DEVICE_ADDR[] = "260110F9";
char NWK_SESSION_KEY[] = "4541D66C36EE255F1B8DA9A5B18E3A60";
char APP_SESSION_KEY[] = "9EEF5FFBC85CBBA54469B7619B7E8F82";
char DEVICE_ID[] = "776173706d6f74652d6c6f726166616c6c32";

////////////////////////////////////////////////////////////

// Define port to use in Back-End: from 1 to 223
uint8_t PORT = 3;

// Define data payload to send (maximum is up to data rate)
char *data = 0;
char *code = 0;

// variable
uint8_t error;
//========================================================================================

//========================================================================================
//=============================== BLE ====================================================

// MAC address of BLE device to find and connect.
// waspmote-lorafall
//char MAC[14] = "B0B448C99D00"; // n7
// waspmote-lorafall2
char MAC[14] = "B0B448C9B205"; //n13


// Aux variable
uint16_t flag = 0;
unsigned char buzz = 0;

// Variable to count notify events
uint8_t eventCounter = 0;

// Accelerometer ranges
#define ACC_RANGE_2G      0
#define ACC_RANGE_4G      1
#define ACC_RANGE_8G      2
#define ACC_RANGE_16G     3

#define MSG_STILL         0
#define MSG_WALK          1
#define MSG_RUN           2
#define MSG_FALL          3

int accRange = ACC_RANGE_4G;

float sensorMpu9250AccConvert(int16_t rawData)
{
    float v;

    switch (accRange)
    {
        case ACC_RANGE_2G:
            //-- calculate acceleration, unit G, range -2, +2
            v = (rawData * 1.0) / (32768/2);
            break;

        case ACC_RANGE_4G:
            //-- calculate acceleration, unit G, range -4, +4
            v = (rawData * 1.0) / (32768/4);
            break;

        case ACC_RANGE_8G:
            //-- calculate acceleration, unit G, range -8, +8
            v = (rawData * 1.0) / (32768/8);
            break;

        case ACC_RANGE_16G:
            //-- calculate acceleration, unit G, range -16, +16
            v = (rawData * 1.0) / (32768/16);
            break;
    }

    return v;
}

int movement(unsigned int x, unsigned int y, unsigned int z) {
    if ((x > 200) || (y > 200) || (z > 200)) return MSG_FALL;
    
    if (x > 100)      return MSG_WALK;
    else if (y > 100) return MSG_RUN;
    else if (z > 100) return MSG_FALL;
    else              return MSG_STILL;
}

void send_msg(unsigned int x, unsigned int y, unsigned int z) {
    //////////////////////////////////////////////
    // 1. Switch on
    //////////////////////////////////////////////

    error = LoRaWAN.ON(SOCKET_LORA);

    // Check status
    if( error == 0 )
    {
        USB.println(F("1. Switch ON OK"));
    }
    else
    {
        USB.print(F("1. Switch ON error = "));
        USB.println(error, DEC);
    }


    //////////////////////////////////////////////
    // 2. Join network
    //////////////////////////////////////////////

    error = LoRaWAN.joinABP();
    // Check status
    if( error == 0 )
    {
        USB.println(F("2. Join network OK"));

        // Convert the event in char
        int msg = movement(x, y, z);
        code = (char *)malloc(sizeof(char));
        itoa(msg, code, 10);
        // Concatenation of the MAC address and the event number.
        // There is no separator between the two.
        data = (char *)malloc((strlen(DEVICE_ID) + 4) * sizeof(char));
        strcpy(data, DEVICE_ID);
        strcat(data, "0");
        strcat(data, code);

        error = LoRaWAN.sendUnconfirmed(PORT, data);
        if( error == 0 )
        {
            USB.println(F("3. Send Unconfirmed packet OK"));
            if (LoRaWAN._dataReceived == true)
            { 
              // Someone falls, LED up
                USB.print(F("   There's data on port number "));
                USB.print(LoRaWAN._port,DEC);
                USB.print(F(".\r\n   Data: "));
                USB.println(LoRaWAN._data);
                buzz = 1;
            }
        }
        else
        {
            USB.print(F("3. Send Unconfirmed packet error = "));
            USB.println(error, DEC);
        }
    }
    else
    {
        USB.print(F("2. Join network error = "));
        USB.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 4. Switch off
    //////////////////////////////////////////////

    error = LoRaWAN.OFF(SOCKET_LORA);

    // Check status
    if( error == 0 )
    {
        USB.println(F("4. Switch OFF OK"));
    }
    else
    {
        USB.print(F("4. Switch OFF error = "));
        USB.println(error, DEC);
    }
}
//========================================================================================

void setup()
{
    USB.println(F("BLE initialization"));

    //=============================== BLE ====================================================
    // 0. Turn BLE module ON
    BLE.ON(SOCKET_BLE);

    //============================== LORA ====================================================
    error = LoRaWAN.ON(SOCKET_LORA);

    // Check status
    if( error == 0 )
    {
        USB.println(F("1. Switch ON OK"));
    }
    else
    {
        USB.print(F("1. Switch ON error = "));
        USB.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 2. Set Device EUI
    //////////////////////////////////////////////

    error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

    // Check status
    if( error == 0 )
    {
        USB.println(F("2. Device EUI set OK"));
    }
    else
    {
        USB.print(F("2. Device EUI set error = "));
        USB.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 3. Set Device Address
    //////////////////////////////////////////////

    error = LoRaWAN.setDeviceAddr(DEVICE_ADDR);

    // Check status
    if( error == 0 )
    {
        USB.println(F("3. Device address set OK"));
    }
    else
    {
        USB.print(F("3. Device address set error = "));
        USB.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 4. Set Network Session Key
    //////////////////////////////////////////////

    error = LoRaWAN.setNwkSessionKey(NWK_SESSION_KEY);

    // Check status
    if( error == 0 )
    {
        USB.println(F("4. Network Session Key set OK"));
    }
    else
    {
        USB.print(F("4. Network Session Key set error = "));
        USB.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 5. Set Application Session Key
    //////////////////////////////////////////////

    error = LoRaWAN.setAppSessionKey(APP_SESSION_KEY);

    // Check status
    if( error == 0 )
    {
        USB.println(F("5. Application Session Key set OK"));
    }
    else
    {
        USB.print(F("5. Application Session Key set error = "));
        USB.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 6. Save configuration
    //////////////////////////////////////////////

    error = LoRaWAN.saveConfig();

    // Check status
    if( error == 0 )
    {
        USB.println(F("6. Save configuration OK"));
    }
    else
    {
        USB.print(F("6. Save configuration error = "));
        USB.println(error, DEC);
    }


    USB.println(F("\n------------------------------------"));
    USB.println(F("Module configured"));
    USB.println(F("------------------------------------\n"));

    LoRaWAN.getDeviceEUI();
    USB.print(F("Device EUI: "));
    USB.println(LoRaWAN._devEUI);

    LoRaWAN.getDeviceAddr();
    USB.print(F("Device Address: "));
    USB.println(LoRaWAN._devAddr);

    USB.println();
}

void loop()
{
    // Accelerometer values
    unsigned int x = 0;
    unsigned int y = 0;
    unsigned int z = 0;

    flag = 0;

    // 1. Look for a specific device
    USB.println(F("First scan for device"));
    USB.print("Look for device: ");
    USB.println(MAC);
    if (BLE.scanDevice(MAC) == 1)
    {
        USB.println(F("2. Join network OK"));
        // 2. Now try to connect with the defined parameters.
        USB.println(F("Device found. Connecting... "));
        flag = BLE.connectDirect(MAC);

        if (flag == 1)
        {
            USB.print("Connected");
            
            if (buzz == 1) {

              unsigned char ioConfig[1];
              ioConfig[0] = 0x1;
              USB.println(F("Writing IO configuration.. "));
              if (BLE.attributeWrite(BLE.connection_handle,  0x50, ioConfig, 1) == 0) {
                USB.println(F("Write OK."));
              } else {
                  USB.println(F("Write NOT OK."));
              }
  
              unsigned char buzzLedOption[1];
                buzzLedOption[0] = 0x3;
                if (BLE.attributeWrite(BLE.connection_handle,  0x4E, buzzLedOption, 1) == 0) {
                  USB.println(F("Write OK."));
                } else {
                    USB.println(F("Write NOT OK."));
                }
                
                delay(3000);
              
                buzzLedOption[0] = 0x0;
                if (BLE.attributeWrite(BLE.connection_handle,  0x4E, buzzLedOption, 1) == 0) {
                  USB.println(F("Write OK."));
                } else {
                    USB.println(F("Write NOT OK."));
                }
                buzz = 0;
                flag = -1;
                
            } else {
              unsigned char measureConfig[2];
              measureConfig[1] = ACC_RANGE_4G;
              measureConfig[0] = 0x7f;
              USB.println(F("Writing Accelerometer configuration.. "));
              if (BLE.attributeWrite(BLE.connection_handle,  0x3C, measureConfig, 2) == 0) {
                USB.println(F("Write OK."));
              } else {
                  USB.println(F("Write NOT OK."));
              }
  
              unsigned char notificationsOption[2] = {0x01, 0x00};
              flag = BLE.attributeWrite(BLE.connection_handle,  0x3A, notificationsOption, 2);
            }
            
            if (flag == 0)
            {
                /* 5. Notify subscription successful. Now start a loop till
                   receive 5 notification or timeout is reached (30 seconds). If disconnected,
                   then exit while loop.

                   NOTE 3: 5 notifications are done by the example BLE_11.
                 */
                eventCounter = 0;
                unsigned long previous = millis();
                //while (( eventCounter < 50 ) && ( (millis() - previous) < 300000))
                while (true)
                {

                  
                    // 5.1 Wait for indicate event.
                    //USB.println(F("Waiting events..."));
                    flag = BLE.waitEvent(5000);
                    
                    if (flag == BLE_EVENT_ATTCLIENT_ATTRIBUTE_VALUE)
                    {
                        USB.print(F("x = "));
                        USB.print(10 * (unsigned long)sensorMpu9250AccConvert((uint16_t)BLE.event[16] << 8) | BLE.event[15]);
                        USB.print(F(", y = "));
                        USB.print(10 * (unsigned long)sensorMpu9250AccConvert((uint16_t)BLE.event[18] << 8) | BLE.event[17]);
                        USB.print(F(", z = "));
                        USB.print(10 * (unsigned long)sensorMpu9250AccConvert((uint16_t)BLE.event[20] << 8) | BLE.event[19]);
                        USB.println();
                        
                        x = 10 * (unsigned long)sensorMpu9250AccConvert((uint16_t)BLE.event[16] << 8) | BLE.event[15];
                        y = 10 * (unsigned long)sensorMpu9250AccConvert((uint16_t)BLE.event[18] << 8) | BLE.event[17];
                        z = 10 * (unsigned long)sensorMpu9250AccConvert((uint16_t)BLE.event[20] << 8) | BLE.event[19];

                        send_msg(x, y, z);

                        eventCounter++;
                        flag = 0;
                    }
                    else
                    {
                        // 5.4 If disconnection event is received, then exit the while loop.
                        if (flag == BLE_EVENT_CONNECTION_DISCONNECTED)
                        {
                            break;
                        }
                    }

                    // Condition to avoid an overflow (DO NOT REMOVE)
                    if( millis() < previous ) previous=millis();

                    if (buzz == 1) break;
                } // end while loop

                //delay(3000);

                // 6. Disconnect. Remember that after a disconnection,
                // the slave becomes invisible automatically.
                if (BLE.getStatus(BLE.connection_handle) == 1)
                {
                    flag = BLE.disconnect(BLE.connection_handle);
                    if (flag != 0)
                    {
                        // Error trying to disconnect
                        USB.print(F("disconnect fail. flag = "));
                        USB.println(flag, DEC);
                        USB.println();
                    }
                    else
                    {
                        USB.println(F("Disconnected."));
                        USB.println();
                    }
                }
                else
                {
                    // Already disconnected
                    USB.println(F("Disconnected.."));
                    USB.println();
                }
            }
            else
            {
                // 4.1 Failed to subscribe.
                USB.println(F("Failed subscribing."));
                USB.println();
            }
        }
        else
        {
            // 2.1 Failed to connect
            USB.println(F("NOT Connected"));
            USB.println();
        }
    }
    else
    {
        // 1.1 Scan failed.
        USB.println(F("Device not found: "));
        USB.println();
    }
}

