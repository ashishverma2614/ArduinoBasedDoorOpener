/*
Darien Nurse
Nurse Timer Prototype
*/

#include <StopWatch.h>

StopWatch MySW;
//extern volatile unsigned long timer0_overflow_count;
const double minute = 1000UL;              // The minute variable represents one second
const double hour = (minute*60UL);         // The hour variable represents one minute in real time
const double day = (hour*24UL);            // The day variable represents twenty-four minutes in real time

const int numberOfDosages = 3;             // The number of dosages need in a 24 hour period
const int dosageInterval = 4;              // The time required between each dosage

double timeUntilNextDose = 0;
boolean resetting = false;                 // This value will become true if 24 hours pass while the device is still in chirp mode
int dayCounter = 1;
int dosagesSoFar = 0;


int speakerPin = 13;
int ledPin = 12;
int buttonPin = 11;                // choose the input pin (for the button)

double timeOfAlarmOn[numberOfDosages];
double timeOfAlarmOff[numberOfDosages];
double creepTime[numberOfDosages];


void setup()
{
  Serial.begin(9600);              // debugging
  pinMode(ledPin, OUTPUT);         // initialize the LED as an output:   
  pinMode(speakerPin, OUTPUT);     // set the speaker as output
  pinMode(buttonPin, INPUT);       // declare pushbutton as input
  if ((numberOfDosages * dosageInterval) > (day/hour))
  {
    Serial.print("It is not possible to have ");
    Serial.print(numberOfDosages);  
    Serial.print(" doses every "); 
    Serial.print(dosageInterval); 
    Serial.print(" hours within one day. Please try again.");
    exit(0);
  }
}

void loop()
{
  if (dosagesSoFar == 0)
  {
    MySW.start();
    alarm();
    digitalWrite(ledPin, LOW);              // turn LED OFF
    timeUntilNextDose = MySW.value() + (hour*dosageInterval);
  } 
  
  while ((dosagesSoFar < numberOfDosages) && !resetting)
  {
   if (MySW.value() >= timeUntilNextDose)
    {
      alarm();
      digitalWrite(ledPin, LOW);              
      timeUntilNextDose = MySW.value() + (hour*dosageInterval);
    }
  }
  
  if ((dosagesSoFar == numberOfDosages && MySW.value() >= day) || resetting)
  {
    resetNurseTimer();
  }
  delay(100);                             // wait a little so as not to send massive amounts of data. On a large time scale, this shouldn't have a significant impact on the program
}

void beep (unsigned char speakerPin, int frequencyInHertz, long timeInMilliseconds)     // the sound producing function
{ 	 
  int x; 	 
  long delayAmount = (long)(1000000/frequencyInHertz);
  long loopTime = (long)((timeInMilliseconds*1000)/(delayAmount*2));
  for (x=0;x<loopTime;x++) 	 
  { 	 
      digitalWrite(speakerPin,HIGH);
      delayMicroseconds(delayAmount);
      digitalWrite(speakerPin,LOW);
      delayMicroseconds(delayAmount);
  } 	 
}

void alarm()
{
  int i;
  timeOfAlarmOn[dosagesSoFar] = MySW.value();
  digitalWrite(ledPin, HIGH);                 // turn LED ON
  alert();
  double chirpDelay = MySW.value() + (minute*5); 
  
  while (digitalRead(buttonPin) == LOW)       // Until the button is pressed, the device will chirp every five minutes.
    {
      if(MySW.value() >= chirpDelay && !resetting)  
      {
        chirp();
        chirpDelay = MySW.value() + (minute*5);
      }    
      if(MySW.value() >= day)                     // If the device has been active for 24 hours, it will reset
      {      
        resetting = true;
      } 
    }
    
  if(!resetting)
  { 
    timeOfAlarmOff[dosagesSoFar] = MySW.value();
    creepTime[dosagesSoFar] = timeOfAlarmOff[dosagesSoFar] - timeOfAlarmOn[dosagesSoFar];
    dosagesSoFar++;
  }
}



void alert()                                // Alarm tone 
{
  beep(speakerPin,2093,250);                //C         
  beep(speakerPin,2793,250);                //F
  beep(speakerPin,4186,500);                //C
}

void chirp()                                 // Chirp tone
{
   beep(speakerPin,3136,500);                // G 
}


void resetNurseTimer()                                    // Returns all values
{
  report();
  resetting = false;
  dosagesSoFar = 0; 
  timeUntilNextDose = 0;
  digitalWrite(buttonPin, LOW);
  digitalWrite(ledPin, LOW); 
  MySW.reset();
}

void report()
{
  int i;
  Serial.print("NurseTimer results for Day: ");
  Serial.println(dayCounter);
  for (i = 0; i < dosagesSoFar; i++)
  {
      Serial.print("Alarm ");
      Serial.print(i + 1);
      Serial.print(" turned on after ");
      Serial.print(timeOfAlarmOn[i]/minute);
      Serial.println(" minutes.");
      Serial.print("Alarm ");
      Serial.print(i + 1);
      Serial.print(" was turned off after ");
      Serial.print(timeOfAlarmOff[i]/minute);
      Serial.println(" minutes.");
      Serial.print("Alarm ");
      Serial.print(i + 1);
      Serial.print(" creep time: ");
      Serial.print(creepTime[i]/minute);
      Serial.println(" minutes.");
  }
  
  if(dosagesSoFar < numberOfDosages)
  {
    Serial.print("Alarm ");
    Serial.print(i + 1);
    Serial.print(" turned on after ");
    Serial.print(timeOfAlarmOn[i]/minute);
    Serial.println(" minutes.");
    Serial.print("The alarm was never turned off. All doses were not received.\n");
  }
  if(dosagesSoFar == numberOfDosages)
  {
    Serial.println("All doses were received!\n");
  }
  dayCounter++;
}
