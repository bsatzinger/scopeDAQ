#define BAUD 115200
#define LED 13
#define BUFFERSIZE 256
#define ANALOG1 1
#define VERSION "0.002"

#include "WProgram.h"
void setup();
void loop();
void setPrescale(int prescale);
void establishContact();
void recordTrace();
void sendTrace();
void waitForTrigger();
int buffer[256];

unsigned int triggerlevel = 512;
int triggerEnable = 0;  //0 records a trace immediately

int timer2start = 0;

void setup()
{
  Serial.begin(BAUD);
  
  //Set up pins
  pinMode(LED, OUTPUT);
  
  establishContact();
  
}

void loop()
{
    int inByte;
  
    if (Serial.available() > 0)
    {
        inByte = Serial.read();
        
        if (inByte == 't')  //read trace
        {
          //waitForTrigger();
           recordTrace();
           sendTrace();
        }
        else if (inByte == 's')  //print scopeduino version
        {
           Serial.print("scopeduino version ");
           Serial.print(VERSION);
           Serial.print("\n"); 
        }
        else if (inByte == 'p') //set prescale for the sample rate timer
        {
           int prescale = Serial.read();
          
           setPrescale(prescale);
        }
        else if (inByte == 'c')  //set initial timer Count
        {
            //timer2 is 8 bits
            
            //wait for the next serial data (1 byte)
            while (Serial.available() < 1){}
            
            //read a byte
            timer2start = Serial.read();
        }
        else if (inByte =='C') //print initial timer Count
        {
            Serial.println(timer2start, DEC); 
        }
        else if (inByte == 'l') //set trigger Level
        {
            //wait for the next serial data (2 bytes)
           while (Serial.available() < 2){} 
           
           //read 2 bytes
           int lowByte = Serial.read();
           int highByte = Serial.read();
           
           //combine the 2 bytes into the 16 bit int value
           triggerlevel = lowByte | (highByte << 8);
           
           //The trigger level is 10 bits, not 16
           triggerlevel = triggerlevel & 0x03FF;
        }
        else if (inByte == 'L') //print trigger level
        {
           Serial.println(triggerlevel, DEC); 
        }
        else if (inByte == 'e') //set trigger enable
        {
           while (Serial.available() < 1){};
          
           int data = Serial.read();
          
           if (data == '1') //enable trigger
           {
               triggerEnable = 1;
           }
           else
           {
               triggerEnable = 0;
           }
        }
        else if (inByte == 'E') //display trigger enable
        {
           Serial.println(triggerEnable, DEC); 
        }
        else
        {
           Serial.print("Unknown Command\n"); 
        }
    }
}

void setPrescale(int prescale)
{
    int bit0 = prescale & 0x01;
    int bit1 = prescale & 0x02;
    int bit2 = prescale & 0x04;
    
    //Set the timer 2 prescale
    TCCR2B = bit2<<CS22 | bit1<<CS21 | bit0<<CS20;
}

void establishContact()
{
   while (Serial.available() <= 0)
  {
     digitalWrite(LED, HIGH);
     delay(150);
     digitalWrite(LED, LOW);
     delay(150);
  } 
}

void recordTrace()
{
  int i;
  
  digitalWrite(LED, HIGH);
  
  for (i = 0; i < BUFFERSIZE; i++)
  {
    buffer[i] = analogRead(ANALOG1);
  }
  
  digitalWrite(LED, LOW);
}

void sendTrace()
{
   int i;
 
   Serial.println(BUFFERSIZE, DEC);
    
   for (i = 0; i < BUFFERSIZE; i++)
   {
      Serial.println(buffer[i], DEC);
   } 
}

void waitForTrigger()
{
    //Wait for the level to fall below the trigger value
    
    while (analogRead(ANALOG1) > triggerlevel)
    {
        digitalWrite(LED, LOW);
        digitalWrite(LED, HIGH);
    }
    
    //Wait for the level to rise above the trigger value
    while (analogRead(ANALOG1) < triggerlevel)
    {
        digitalWrite(LED, LOW);
        digitalWrite(LED, HIGH);
    }
    
    //Trigger happened, return
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

