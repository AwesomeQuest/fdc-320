#include <SoftwareSerial.h>
#include <stdint.h>
#include "DHT.h"

#define READTIMEOUT 100000 // microseconds


#define MULTIPLEXERINPUTPIN 4
#define MULTIPLEXERDATAPIN1 6
#define MULTIPLEXERDATAPIN1 7
#define MULTIPLEXERDATAPIN1 8
#define MULTIPLEXERDATAPIN1 9

#define DHT22_PIN 2
DHT dht22(DHT22_PIN, DHT22);

enum {
	SUCCESS,
	ERROR_CRC_MISSMATCH,
	ERROR_TIMEOUT
};

#define rxPin 3
#define txPin 5

SoftwareSerial modbus (rxPin, txPin);

void setup() {
	// put your setup code here, to run once:
	dht22.begin();

	pinMode(rxPin, INPUT);
	pinMode(txPin, OUTPUT);

	Serial.begin(9600);
	modbus.begin(9600);
}

void loop() {
	uint8_t inchar = Serial.read();

	if (inchar == '\n' || inchar == '\r') {
		uint32_t T = micros();
		while (Serial.available() < 4) {
			if (micros() - T > READTIMEOUT) {
				Serial.println("SERIAL TIMEOUT");
				return 0;
			}
		}
		uint8_t id = Serial.read();
		uint8_t adr = Serial.read();
		uint8_t crc_hi = Serial.read();
		uint8_t crc_lo = Serial.read();
		uint16_t crcret = crc_hi << 8 | crc_lo;

		uint8_t recbuff[3] = {inchar, id, adr};
		uint16_t crccalc = crc16(recbuff, 3);
		if (crccalc != crcret)
		{
			Serial.println("ID CRC MISMATCH");
			Serial.print("Sent CRC: 0x");
			Serial.println(crcret, HEX);
			Serial.print("Calc CRC: 0x");
			Serial.println(crccalc, HEX);
			return 0;
		}

		uint8_t cnt = getregsize((uint16_t)adr);

		if (cnt == 0xff) {
			Serial.print("INCORRECT REGISTER: 0x");
			Serial.println(adr, HEX);
			return 0;
		}

		if (inchar == '\n') {
			uint8_t bufflen = 0;
			uint8_t* buff = readRegisters(&bufflen, id, (uint16_t)adr, (uint16_t)cnt);
			if (bufflen == 0xff) {
				Serial.println("FAIL");
				Serial.print("The error code is: ");
				Serial.println((uint8_t)buff);
				free(buff);
				return 0;
			}
			Serial.println("SUCCESS");
			Serial.write(buff, bufflen);
			Serial.println();

			free(buff);
		} else if (inchar == '\r') {
			uint8_t* databuff = calloc(cnt, 2);
			uint32_t T = micros();
			while (Serial.available() < cnt*2 + 2) {
				if (micros() - T > READTIMEOUT) {
					Serial.println("SERIAL TIMEOUT");
					return 0;
				}
			}
			for (size_t i = 0; i < cnt*2; i++)
			{
				databuff[i] = Serial.read();
			}
			crc_hi = Serial.read();
			crc_lo = Serial.read();
			crcret = crc_hi << 8 | crc_lo;

			uint16_t crccalc = crc16(databuff, cnt*2);
			if (crccalc != crcret)
			{
				Serial.println("DATA CRC MISMATCH");
				Serial.print("Sent CRC: 0x");
				Serial.println(crcret, HEX);
				Serial.print("Calc CRC: 0x");
				Serial.println(crccalc, HEX);
				return 0;
			}

			uint8_t err = writeRegisters(id, (uint16_t)adr, (uint16_t)cnt, databuff, cnt*2);

			free(databuff);
			databuff = NULL;

			if (err != 0)
			{
				Serial.println("FAIL");
				Serial.print("The error code is: ");
				Serial.println(err);
				return 0;
			}

			Serial.println("SUCCESS");
		}
	} else if (inchar == 0x0c) {
		float temp = dht22.readTemperature();
		float humi = dht22.readHumidity();

		uint8_t buff[2+1+8+2];
		buff[0] = 'T';
		buff[1] = 'H';
		buff[2] = 0x08;
		memcpy(buff+3, &temp, 4);
		memcpy(buff+3+4, &humi, 4);
		uint16_t crc = crc16(buff, 2+1+8);
		memcpy(buff+3+4+4, &crc, 2);

		Serial.write(buff, sizeof(buff));
	} else if (inchar == 0x0b)
	{
		uint32_t T = micros();
		while (Serial.available() < 4) {
			if (micros() - T > READTIMEOUT) {
				Serial.println("SERIAL TIMEOUT");
				return 0;
			}
		}
		uint8_t controlbyte = Serial.read();
		uint8_t crc_hi = Serial.read();
		uint8_t crc_lo = Serial.read();
		uint16_t crcret = crc_hi << 8 | crc_lo;

		uint8_t recbuff[2] = {inchar, controlbyte};
		uint16_t crccalc = crc16(recbuff, 3);
		if (crccalc != crcret)
		{
			Serial.println("CRC MISMATCH");
			Serial.print("Sent CRC: 0x");
			Serial.println(crcret, HEX);
			Serial.print("Calc CRC: 0x");
			Serial.println(crccalc, HEX);
			return 0;
		}

		digitalWrite(MULTIPLEXERDATAPIN1, controlbyte & 0b00000001);
		digitalWrite(MULTIPLEXERDATAPIN2, controlbyte & 0b00000010 >> 1);
		digitalWrite(MULTIPLEXERDATAPIN3, controlbyte & 0b00000100 >> 2);
		digitalWrite(MULTIPLEXERDATAPIN4, controlbyte & 0b00001000 >> 3);
		digitalWrite(MULTIPLEXERINPUTPIN, controlbyte & 0b00010000 >> 4);

		Serial.println("SUCCESS");
	}
	
}

// Sends a read registers modbus request
/*
	If the bufflength is equal to 0xff then there has been an error
	and the returned value is not a valid pointer but an error code.
*/
static uint8_t* readRegisters(
	uint8_t* bufflength,
	uint8_t id,
	uint16_t adr,
	uint16_t regcount
)
{
	uint8_t buff[8];
	buff[0] = id;
	buff[1] = 0x03;
	buff[2] = adr >> 8;
	buff[3] = adr;
	buff[4] = regcount >> 8;
	buff[5] = regcount;

	uint16_t crc = crc16(buff,(uint16_t)(8 - 2));
	buff[6] = crc >> 8;
	buff[7] = crc;

	while (modbus.available() > 0) {
		Serial.println("Flushing modbus");
		modbus.read();
	}
	modbus.write(buff, sizeof(buff));

	uint32_t T = micros();
	while (modbus.available() < 3) {
		if (micros() - T > READTIMEOUT) {
			*bufflength = 0xff;
			return (uint8_t*)ERROR_TIMEOUT;
		}
		Serial.println("Waiting for modbus");
	}
	
	uint8_t retid = modbus.read();
	uint8_t retfunc = modbus.read();
	uint8_t retbnum = modbus.read();
	
	// make a buffer with room for everything
	//  1    1        1        x   2
	// id func dbufflen databuff crc
	uint8_t retbufflen = 3+retbnum+2;
	uint8_t* retbuff = calloc(retbufflen, 1);
	retbuff[0] = retid;
	retbuff[1] = retfunc;
	retbuff[2] = retbnum;

	T = micros();
	while (modbus.available() < retbnum + 2) {
		if (micros() - T > READTIMEOUT) {
			*bufflength = 0xff;
			return (uint8_t*)ERROR_TIMEOUT;
		}
		Serial.println("Waiting for modbus");
	}

	for (uint8_t i = 0; i < retbnum + 2; i++)
	{
		retbuff[3 + i] = modbus.read();
	}

	uint16_t retcrc = retbuff[retbufflen-2] << 8 | retbuff[retbufflen-1];
	uint16_t appcrc = crc16(retbuff, retbufflen-2);

	if (retcrc != appcrc){
		free(retbuff);
		*bufflength = 0xff;
		return (uint8_t*)ERROR_CRC_MISSMATCH;
	}
	if (retbuff[1] >= 0x80){
		free(retbuff);
		*bufflength = 0xff;
		return retbuff[1];
	}
	*bufflength = retbufflen;
	return retbuff;
}

static uint8_t writeRegisters(
	uint8_t id,
	uint16_t adr,
	uint16_t regcount,
	uint8_t* databuff,
	uint8_t databufflen
)
{
	// make a buffer with room for everything
	//  1    1   2   2        1        x   2
	// id func adr cnt dbufflen databuff crc
	uint8_t bufflen = 8 + 1 + databufflen;
	uint8_t* buff = calloc(bufflen,1);
	buff[0] = id;
	buff[1] = 0x10;
	buff[2] = adr >> 8;
	buff[3] = adr;
	buff[4] = regcount >> 8;
	buff[5] = regcount;

	buff[6] = databufflen;
	memcpy(buff+7, databuff, databufflen);

	uint16_t crc = crc16(buff,(uint16_t)(bufflen - 2));
	buff[bufflen-2] = crc >> 8;
	buff[bufflen-1] = crc;
	
	while (modbus.available() > 0) {
		Serial.println("Flushing modbus");
		modbus.read();
	}
	modbus.write(buff, bufflen);

	free(buff);
	buff = NULL;

	uint32_t T = micros();
	while (modbus.available() < 7) {
		if (micros() - T > READTIMEOUT) {
			return ERROR_TIMEOUT;
		}
		Serial.println("Waiting for modbus");
	}
	uint8_t retbuff[8];
	for (uint8_t i = 0; i < 8; i++)
	{
		// Maybe this is better?
		// while (modbus.available() < 0)
		// {
		// 	delay(1);
		// }
		retbuff[i] = modbus.read();
	}

	uint16_t retcrc = retbuff[6] << 8 | retbuff[7];
	uint16_t appcrc = crc16(retbuff, 6);

	// TODO add more error checking like making sure
	// retbuff contains the right values based on the
	// request

	if (retcrc != appcrc)
		return ERROR_CRC_MISSMATCH;

	if (retbuff[1] >= 0x80)
		return retbuff[1];

	return SUCCESS;
}

void printhexs(uint8_t* buff, uint8_t bufflen) {
	for (uint8_t i = 0; i < bufflen; i++)
	{
		Serial.print("0x");
		Serial.print(buff[i], HEX);
		Serial.print(" ");
	}
}

// A return value of -1 means the register is not valid
uint8_t getregsize(uint16_t adr) {
	switch (adr)
	{
	case 0x0001:
		return 1;
		break;
	case 0x0010:
		return 2;
		break;
	case 0x0016:
		return 1;
		break;
	case 0x0020:
		return 2;
		break;
	case 0x0026:
		return 1;
		break;
	case 0x0030:
		return 1;
		break;
	case 0x0031:
		return 1;
		break;
	case 0x0032:
		return 1;
		break;
	case 0x002a:
		return 1;
		break;
	case 0x002d:
		return 1;
		break;
	case 0x0041:
		return 1;
		break;
	case 0x0051:
		return 2;
		break;
	case 0x0053:
		return 1;
		break;
	case 0x0061:
		return 1;
		break;
	case 0x0080:
		return 5;
		break;
	case 0x0087:
		return 2;
		break;
	
	default:
		return -1;
		break;
	}
}

/* Table of CRC values for high-order byte */
#if defined(ARDUINO) && defined(__AVR__)
#include <avr/pgmspace.h>
static PROGMEM const uint8_t table_crc_hi[] = {
#else
static const uint8_t table_crc_hi[] = {
#endif
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
	0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
	0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
	0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40
};

/* Table of CRC values for low-order byte */
#if defined(ARDUINO) && defined(__AVR__)
#include <avr/pgmspace.h>
static PROGMEM const uint8_t table_crc_lo[] = {
#else
static const uint8_t table_crc_lo[] = {
#endif
	0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06,
	0x07, 0xC7, 0x05, 0xC5, 0xC4, 0x04, 0xCC, 0x0C, 0x0D, 0xCD,
	0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09,
	0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A,
	0x1E, 0xDE, 0xDF, 0x1F, 0xDD, 0x1D, 0x1C, 0xDC, 0x14, 0xD4,
	0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3,
	0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3,
	0xF2, 0x32, 0x36, 0xF6, 0xF7, 0x37, 0xF5, 0x35, 0x34, 0xF4,
	0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A,
	0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38, 0x28, 0xE8, 0xE9, 0x29,
	0xEB, 0x2B, 0x2A, 0xEA, 0xEE, 0x2E, 0x2F, 0xEF, 0x2D, 0xED,
	0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26,
	0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60,
	0x61, 0xA1, 0x63, 0xA3, 0xA2, 0x62, 0x66, 0xA6, 0xA7, 0x67,
	0xA5, 0x65, 0x64, 0xA4, 0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F,
	0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68,
	0x78, 0xB8, 0xB9, 0x79, 0xBB, 0x7B, 0x7A, 0xBA, 0xBE, 0x7E,
	0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5,
	0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71,
	0x70, 0xB0, 0x50, 0x90, 0x91, 0x51, 0x93, 0x53, 0x52, 0x92,
	0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C,
	0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B,
	0x99, 0x59, 0x58, 0x98, 0x88, 0x48, 0x49, 0x89, 0x4B, 0x8B,
	0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
	0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42,
	0x43, 0x83, 0x41, 0x81, 0x80, 0x40
};

uint16_t crc16(uint8_t *buffer, uint16_t buffer_length)
{
	uint8_t crc_hi = 0xFF; /* high CRC byte initialized */
	uint8_t crc_lo = 0xFF; /* low CRC byte initialized */
	unsigned int i; /* will index into CRC lookup */

	/* pass through message buffer */
	while (buffer_length--) {
		i = crc_hi ^ *buffer++; /* calculate the CRC  */
#if defined(ARDUINO) && defined(__AVR__)
		crc_hi = crc_lo ^ pgm_read_byte_near(table_crc_hi + i);
		crc_lo = pgm_read_byte_near(table_crc_lo + i);
#else
		crc_hi = crc_lo ^ table_crc_hi[i];
		crc_lo = table_crc_lo[i];
#endif
	}

	return (crc_hi << 8 | crc_lo);
}
