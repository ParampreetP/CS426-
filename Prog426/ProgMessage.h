#ifndef __ProgApp_H
#define __ProgApp_H
//header file to define format of payload packet

enum
{
	//3 messageIDS, for photo, temp, and humidity, With seperate unique IDS
	//unique active messageID (127-255)
	AM_PROG_PHOTO_MESSAGE = 150,
	AM_PROG_TEMP_MESSAGE = 180,
	AM_PROG_HUMIDITY_MESSAGE = 200,
};

typedef nx_struct prog_message//structure name, defines how the payload will look like
{
	//3 integers, one for temperature, humidity, ambient light intensity
	nx_uint16_t photoReading;//ambient light intensity
	nx_uint16_t tempReading;//temp
	nx_uint16_t humidityReading;//humidity
} prog_message_t;

#endif //__ProgApp_H
