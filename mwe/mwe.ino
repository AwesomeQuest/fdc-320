#include <SoftwareSerial.h>
#include <stdint.h>

#define rxPin 3
#define txPin 5

SoftwareSerial modbus (rxPin, txPin);

void setup() {
	pinMode(rxPin, INPUT);
	pinMode(txPin, OUTPUT);

	Serial.begin(9600);
	modbus.begin(9600);
}

void loop() {
  delay(1000);

  uint8_t buff[] = {0x01, 0x03, 0x00, 0x10, 0x00, 0x02, 0xc5, 0xce};
  uint8_t bufflen = 8;
  Serial.println("Sending message");
  modbus.write(buff,bufflen);


  Serial.println("Reading message");
  while (modbus.available() > 0) {
    Serial.print("0x");
		Serial.print(modbus.read(), HEX);
		Serial.print(" ");
	}
  Serial.println();
}
