#define BAUD 115200
#define LED 13
#define BUFFERSIZE 256
#define ANALOG1 1
#define VERSION "0.001"

int buffer[256];

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
        
        if (inByte == 't')
        {
           recordTrace();
           sendTrace();
        }
        else if (inByte == 's')
        {
           Serial.print("scopeduino version ");
           Serial.print(VERSION);
           Serial.print("\n"); 
        }
        else
        {
           Serial.print("Unknown Command\n"); 
        }
    }
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
