#include <SoftwareSerial.h>
#define RFID_READ 0x01
#define txPin 6
#define rxPin 8

SoftwareSerial mySerial(rxPin, txPin);
int val;
int runs = 0;

void setup()
{
  Serial.begin(9600);
  Serial.println("RFID Read/Write Test");
  mySerial.begin(9600);
  pinMode(txPin, OUTPUT);    
  pinMode(rxPin, INPUT);      
}

void suppressAll()                                //suppresses the "null result" from being printed if no RFID tag is present
{
    if(mySerial.available() > 0)
    { mySerial.read();
      suppressAll();
    }
}

void loop()
{
 int val;
  mySerial.print("!RW");
  mySerial.write(byte(RFID_READ));
  mySerial.write(byte(32));

  if(mySerial.available() > 0)
  {      
    val = mySerial.read();                        //The mySerial.read() procedure is called, but the result is not printed because I don't want the "error message: 1" cluttering up the serial monitor
      if (val != 1)                                   //If the error code is anything other than 1, then the RFID tag was not read correctly and any data collected is meaningless. In this case since we don't care about the resultant values they can be suppressed
       {suppressAll();}                              
  }      


 if(mySerial.available() > 0) {      
    val = mySerial.read();
    Serial.print("1st:");
    Serial.println(val, HEX);
    }

if(mySerial.available() > 0) {        
    val = mySerial.read();
    Serial.print("2nd:");
    Serial.println(val, HEX);
    }

if(mySerial.available() > 0) {      
    val = mySerial.read();
    Serial.print("3rd:");
    Serial.println(val, HEX);
    }

if(mySerial.available() > 0) {          
    val = mySerial.read();
    Serial.print("4th:");
    Serial.println(val, HEX);
    Serial.println("-----------------");
    }  

delay(750);
}
