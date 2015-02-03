//Code to write data to Parallax RFID reader/writer 28440 from Arduino
//Program writes to one of the 29 user-defined addresses (3-31) as define by whichSpace
//The four bytes to be written are defined by first, second, third, and fourth
//Coded by vgrhcp, adapted to arduino 1.0 by sebflippers

 #include <SoftwareSerial.h>
 #define RFID_WRITE 0x02
 #define txPin 6
 #define rxPin 8

 #define whichSpace 4

 #define first 1                 // first, second, thrid, and fourth are four arbitrary values which will be written to the RFID tag at address whichSpace
 #define second 26
 #define third 3
 #define fourth 27

SoftwareSerial mySerial(rxPin, txPin);

void setup()
{
  Serial.begin(9600);
  Serial.println("RFID Write Test");
  mySerial.begin(9600);
  pinMode(txPin, OUTPUT);     
  pinMode(rxPin, INPUT);      
}


void suppressAll()                                      //Keeps error code & the "write confirmation" codes from being printed in the serial monitor       
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
  mySerial.write(byte(RFID_WRITE));
  mySerial.write(byte(whichSpace));
  mySerial.write(byte(first));
  mySerial.write(byte(second));
  mySerial.write(byte(third));
  mySerial.write(byte(fourth));

if(mySerial.available() > 0) {        
    val = mySerial.read();
    if (val == 1)                                        //If data was written successfully
      { Serial.println("Data written succesfully!");
        suppressAll();
      }
    else suppressAll();                                  //If an error occured during writing, discard all data recieved from the RFID writer
    }
delay(250);
}
