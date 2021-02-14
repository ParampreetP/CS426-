#include "ProgMessage.h"

//config file
configuration ProgAppC
{
}
implementation{


	components ProgP;//own module
	components MainC;//starting point of program
	components new HamamatsuS10871TsrC() as PhotoC; //driver componenent for ambient light.. rename as PhotoC

	components new SensirionSht11C() as TempC;//temp and humidity
	//components new SensirionSht11C() as HumidityC;


	//radio computation
	components ActiveMessageC;

	components new AMSenderC(AM_PROG_PHOTO_MESSAGE) as AMSenderPhotoC;//photo sender
	components new AMReceiverC(AM_PROG_PHOTO_MESSAGE) as AMReceiverPhotoC;//photo receiver

	components new AMSenderC(AM_PROG_TEMP_MESSAGE) as AMSenderTempC;//temp sender
	components new AMReceiverC(AM_PROG_TEMP_MESSAGE) as AMReceiverTempC;//temp receiver

	components new AMSenderC(AM_PROG_HUMIDITY_MESSAGE) as AMSenderHumidityC;//humidity sender
	components  new AMReceiverC(AM_PROG_HUMIDITY_MESSAGE) as AMReceiverHumidityC;//humidity receiver


	components LedsC;//used to control the onboard LEDS
	components new TimerMilliC() as Timer0;//3 timers
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;

	//Add printf components
	components PrintfC;
  	components SerialStartC;

	//connect components to own components, wiring
	//own component ->  components

	ProgP.Boot ->MainC;
	ProgP.Photo -> PhotoC;//light
	ProgP.Temp -> TempC.Temperature;//Temperature 
	ProgP.Humidity -> TempC.Humidity;//Humidity
	
	ProgP.RadioControl -> ActiveMessageC;

	//3 seperate temp,photo, and humidity AMSend
	ProgP.AMSendPhoto -> AMSenderPhotoC;
	ProgP.AMSendTemp -> AMSenderTempC;
	ProgP.AMSendHumidity -> AMSenderHumidityC;

	//3 seperate temp,photo, and humidity Receieve
	ProgP.ReceivePhoto -> AMReceiverPhotoC;
	ProgP.ReceiveTemp -> AMReceiverTempC;
	ProgP.ReceiveHumidity -> AMReceiverHumidityC;

	ProgP.Packet -> ActiveMessageC;
	
	ProgP.Leds -> LedsC;
	//3 seperate timers for each temp,photo,and humidity
	ProgP.Timer0 -> Timer0;
	ProgP.Timer1 -> Timer1;
	ProgP.Timer2 -> Timer2;


}
