#define BAUD 115200
#define LED 13
#define BUFFERSIZE 256
#define ANALOG1 1
#define VERSION "0.002"

#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

int buffer1[BUFFERSIZE];
int buffer2[BUFFERSIZE];

int ch1Input = 0;
int ch2Input = 4;

unsigned char timer2start = 253;
unsigned int triggerlevel = 512;
unsigned int triggerEnable = 0;
unsigned int recordingTrace;
unsigned int index;

void setup()
{
  Serial.begin(BAUD);
  
  triggerlevel = 512;
  
  //prescale of 16
  //max sample rate 77k
  sbi(ADCSRA, ADPS2);
  cbi(ADCSRA, ADPS1);
  cbi(ADCSRA, ADPS0);
  
  /*
  //prescale of 8
  //max sample rate 153k
  cbi(ADCSRA, ADPS2);
  sbi(ADCSRA, ADPS1);
  sbi(ADCSRA, ADPS0);
  */
  
  //Set up pins
  pinMode(LED, OUTPUT);
  
  pinMode(14, INPUT);
  digitalWrite(14, HIGH);
  
    pinMode(15, INPUT);
  digitalWrite(15, HIGH);
  
    pinMode(16, INPUT);
  digitalWrite(16, HIGH);
  
    pinMode(17, INPUT);
  digitalWrite(17, HIGH);
  
    pinMode(18, INPUT);
  digitalWrite(18, HIGH);
  
    pinMode(19, INPUT);
  digitalWrite(19, HIGH);
  
  SetupTimer2();
  
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
        else if (inByte = 'a')   //set channel A vertical scale
        {
           while (Serial.available() < 1){};
           
           int data = Serial.read();
          
          //data contains the analog input number
          if (data == '0')
          {
             ch1Input = 0; 
          }
          else if (data == '1')
          {
             ch1Input = 1; 
          }
          else
          {
             ch1Input = 2; 
          }
        }
        else if (inByte = 'b')
        {
          unsigned char data = Serial.read();
          
          //data contains the analog input number
           ch2Input = data;
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
  int triggerResult = 0;
  
  if (triggerEnable == 1)
  {
    digitalWrite(LED, HIGH);
    triggerResult = waitForTrigger(); 
    digitalWrite(LED, LOW);
  }
  
  //the trigger was aborted because of serial data
  if (triggerResult == 5)
  {
      index = 0;
      recordingTrace = 0;
      return; 
  }
  
  //Allow the ISR to record trace data
  index = 0;
  recordingTrace = 1;
  
  //Wait for the trace to get recorded before returning
  while (recordingTrace == 1)
  {
     delay(1); 
  }
  
  //Return
}

void sendTrace()
{
   int i;
 
   Serial.println(BUFFERSIZE, DEC);
    
   for (i = 0; i < BUFFERSIZE; i++)
   {
      Serial.println(buffer1[i], DEC);
   } 
   
   Serial.println(BUFFERSIZE, DEC);
    
   for (i = 0; i < BUFFERSIZE; i++)
   {
      Serial.println(buffer2[i], DEC);
   } 
}

int waitForTrigger()
{
    //Wait for the level to fall below the trigger value
    unsigned int count = 0;
    unsigned int count2 = 0;
    
    
    while ((analogRead(ch1Input) > triggerlevel) && (count2 < 3))
    {         
        count++;
        
        if (count > 65000)
        {
           count = 0;
           count2++; 
        }
    }
    
    count = 0;
    count2 = 0;
    
    //Wait for the level to rise above the trigger value
    while ((analogRead(ch1Input) < triggerlevel) && (count2 < 3))
    {        
        count++;
        
        if (count > 65000)
        {
           count = 0;
           count2++; 
        }
    }
    
    //Trigger happened, return (possible timeout)
    
    return 0;  //success!
}


void flashLED()
{
     digitalWrite(LED, HIGH);
     delay(150);
     digitalWrite(LED, LOW);
     delay(150);
}



void SetupTimer2(void)
{
  
  TCCR2A = 0;

  //256 prescaling
  TCCR2B = 1<<CS22 | 1<<CS21 | 0<<CS20; 

  //Timer2 Overflow Interrupt Enable   
  TIMSK2 = 1<<TOIE2;

  //load the timer for its first cycle
  TCNT2=timer2start; 
}

//Timer2 overflow interrupt vector handler

ISR(TIMER2_OVF_vect)
{
  //Disable interrupts
  cli();
  
  //Currently recording trace?
  if(recordingTrace == 1)
  {
      
      if (index > (BUFFERSIZE - 1))
      {
         //Done recording the trace
         recordingTrace = 0;
      }
      else
      {
 
          buffer1[index] = analogRead(ch1Input);

          buffer2[index] = analogRead(ch2Input);

        index++;
      }  
  }
  
  
  //Reset the counter for the next period
  TCNT2=timer2start;    //TCNT2 = timr2start - TCNT2 might compensate for the (variable) ISR time

  //Enable interrupts
  sei();
}
