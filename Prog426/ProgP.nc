#include "Timer.h"
#include "SensirionSht11.h"
#include "printf.h"


//module file
module ProgP
{
	//declare all interfaces from components


	uses interface Boot;
	
	uses interface Read<uint16_t> as Photo;
	uses interface Read<uint16_t> as Temp;
	uses interface Read<uint16_t> as Humidity;


	uses interface SplitControl as RadioControl;

	uses interface AMSend as AMSendPhoto;
	uses interface AMSend as AMSendTemp;
	uses interface AMSend as AMSendHumidity;

	uses interface Receive as ReceivePhoto;
	uses interface Receive as ReceiveTemp;
	uses interface Receive as ReceiveHumidity;
	uses interface Packet;

	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Timer<TMilli> as Timer2;
}
implementation
{
	//conversion integers
	uint16_t photoC;
	uint16_t tempC;
	uint16_t humidityC;

	//variable to store the msg
	message_t buf;
	message_t *receivedBuf;

	event void RadioControl.stopDone(error_t err) {}
	
	//declare local task.. function defn below
	
	//generate reading 
	task void readHumiditySensor();
  	task void readPhotoSensor();
  	task void readTempSensor();
  	
	//transmit data 
	task void sendPhotoPacket();
  	task void sendHumidityPacket();
  	task void sendTempPacket();
 




	event void Boot.booted()//triggered automatically when system begins to operate
	{
		call RadioControl.start();//start radio
	}

	event void RadioControl.startDone(error_t err)
	{
		if(TOS_NODE_ID != 2)//other device will not start a timer or perform sensing. only ID=2 will perform the sensing
		{
			call Timer0.startPeriodic(1000);//1 second, every 1 second timer0 will generate an interrupt
			call Timer1.startPeriodic(2000);//2 second
			call Timer2.startPeriodic(4000);//4 second
                }
	}

	//temp timer fires
	event void Timer0.fired()//fire timer when generates an interrupt
	{
		post readTempSensor();//post temp read sensor task to generate the reading
	}

	//photo timer fires
	event void Timer1.fired()
	{
		post readPhotoSensor();//post Photo read sensor task to generate the reading
		
	}

	//humidity timer fires
	event void Timer2.fired()
	{
		post readHumiditySensor();//post humidity read sensor task to generate the reading
	}

	
	

	//READ FROM SENSORS

	//photo
  	task void readPhotoSensor() {
    		if(call Photo.read() != SUCCESS) {//if not equal to success.. repost the task
      			post readPhotoSensor();
    		}
  	}

	//humidity
  	task void readHumiditySensor() {
    		if(call Humidity.read() != SUCCESS){
      			post readHumiditySensor();
		}
  	}

	//temp
  	task void readTempSensor() {
    		if(call Temp.read() != SUCCESS){
      			post readTempSensor();
		}
  	}

	
	//READ DONES FOE EACH SENSOR. after we get the reading, trigger the readDone event

  	event void Photo.readDone(error_t err, uint16_t value) {
    		if(err != SUCCESS)
      			post readPhotoSensor();//check return value. if not equal to success then repost the task
    		
		else {// if err equal to success... sensing chip has the reading
      			
			prog_message_t * payload = (prog_message_t *)call
        							Packet.getPayload(&buf, sizeof(prog_message_t));//use packet interface to grab the payload
			
			photoC=2.5*((value)/4096.0)*6250.0;//Convert value, change in the payload, so reciever already has converted value
      			payload->photoReading = photoC;//point photoReading to the converted photo value
      			post sendPhotoPacket();//transmit the data
    		}
  	}

  	event void Humidity.readDone(error_t err, uint16_t value) {
    		if(err != SUCCESS)
      			post readHumiditySensor();
    		else {
      			prog_message_t * payload = (prog_message_t *)call
        						Packet.getPayload(&buf, sizeof(prog_message_t));

			humidityC =(-4 +0.0405*(value))+(-0.0000028*pow(value,2));
     			payload->humidityReading = humidityC;
      			post sendHumidityPacket();
    		}
 	 }
	
  	event void Temp.readDone(error_t err, uint16_t value) {
   		 if(err != SUCCESS)
      			post readTempSensor();
    		else {
      			prog_message_t * payload = (prog_message_t *)call
        					Packet.getPayload(&buf, sizeof(prog_message_t));

			tempC = (-39.60 + 0.01 *value);
      			payload->tempReading = tempC;
      			post sendTempPacket();
    		}
  	}




	//Send Photo Packet
  	task void sendPhotoPacket() {
    		if(call AMSendPhoto.send(AM_BROADCAST_ADDR, &buf, sizeof(prog_message_t)) != SUCCESS)
      			post sendPhotoPacket();
  		}
  
	event void AMSendPhoto.sendDone(message_t * msg, error_t err) {
    		if(err != SUCCESS)
      		post sendPhotoPacket();
  	}


	//Send Humidity Packet
  	task void sendHumidityPacket() {
    		if(call AMSendHumidity.send(AM_BROADCAST_ADDR, &buf, sizeof(prog_message_t)) != SUCCESS)
      		post sendHumidityPacket();
  	}
  	
	event void AMSendHumidity.sendDone(message_t * msg, error_t err) {
    		if(err != SUCCESS)
      		post sendHumidityPacket();
  	}

  	//Send Temp Packet
  	task void sendTempPacket() {
    		if(call AMSendTemp.send(AM_BROADCAST_ADDR, &buf, sizeof(prog_message_t)) != SUCCESS)
      		post sendTempPacket();
  	}
  	event void AMSendTemp.sendDone(message_t * msg, error_t err) {
    		if(err != SUCCESS)
      		post sendTempPacket();
  	}



	//Receive Photo Packet
	event message_t * ReceivePhoto.receive(message_t * msg, void * payload, uint8_t len)
	{
		
			prog_message_t * demoPayload = (prog_message_t *)payload;//local variable
			call Leds.led1Toggle();//toggle led1 because recieving a photo reading
			receivedBuf = msg;
			printf(" photo reading %d\r\n", demoPayload->photoReading);//print photo reading value in the demopayload
			printfflush();//clear print buffer
			return msg;	
	}


	//Receive humidity Packet
	event message_t * ReceiveHumidity.receive(message_t * msg, void * payload, uint8_t len)
	{
		
			prog_message_t * demoPayload = (prog_message_t *)payload;
			call Leds.led2Toggle();//toggle led2 because recieving a humidity reading
			receivedBuf = msg;
			printf(" humidity reading %d\r\n", demoPayload->humidityReading);//print humidity reading value in the demopayload
			printfflush();//clear print buffer
			return msg;	
	}



	//Receive temp Packet
	event message_t * ReceiveTemp.receive(message_t * msg, void * payload, uint8_t len)
	{
		
			prog_message_t * demoPayload = (prog_message_t *)payload;
			call Leds.led0Toggle();//toggle led0 because recieving a temp reading
			receivedBuf = msg;
			printf(" temp reading %d\r\n", demoPayload->tempReading);//print temp reading value in the demopayload
			printfflush();//clear print buffer
			return msg;	
	}
}
