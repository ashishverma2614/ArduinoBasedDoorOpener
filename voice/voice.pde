#include <NewSoftSerial.h>
NewSoftSerial port(12,13);

#include <EasyVR.h>
EasyVR easyvr(port);
int LED = 13;

//Groups and Commands
enum Groups
{
  GROUP_0  = 0,
  GROUP_1  = 1,
};

enum Group0 
{
  G0_HELLO = 0,
};

enum Group1 
{
  G1_LIGHT_ON = 0,
  G1_LIGHT_OFF = 1,
};


EasyVRBridge bridge;

int8_t group, idx;

void setup()
{
  pinMode(LED,OUTPUT);
  // bridge mode?
  if (bridge.check())
  {
    cli();
    bridge.loop(0, 1, 12, 13);
  }
  // run normally
  Serial.begin(9600);
  port.begin(9600);

  if (!easyvr.detect())
  {
    Serial.println("EasyVR not detected!");
    for (;;);
  }

  easyvr.setPinOutput(EasyVR::IO1, LOW);
  Serial.println("EasyVR detected!");
  easyvr.setTimeout(5);
  easyvr.setLanguage(0);

  group = EasyVR::TRIGGER; //<-- start group (customize)
}

void action();

void loop()
{
  easyvr.setPinOutput(EasyVR::IO1, HIGH); // LED on (listening)

  Serial.print("Say a command in Group ");
  Serial.println(group);
  easyvr.recognizeCommand(group);

  do
  {
    // can do some processing while waiting for a spoken command
  }
  while (!easyvr.hasFinished());
  
  easyvr.setPinOutput(EasyVR::IO1, LOW); // LED off

  idx = easyvr.getWord();
  if (idx >= 0)
  {
	// built-in trigger (ROBOT)
	// group = GROUP_X; <-- jump to another group X
	return;
  }
  idx = easyvr.getCommand();
  if (idx >= 0)
  {
    // print debug message
    uint8_t train = 0;
    char name[32];
    Serial.print("Command: ");
    Serial.print(idx);
    if (easyvr.dumpCommand(group, idx, name, train))
    {
      Serial.print(" = ");
      Serial.println(name);
    }
    else
      Serial.println();
    easyvr.playSound(0, EasyVR::VOL_FULL);
    // perform some action
    action();
  }
  else // errors or timeout
  {
    if (easyvr.isTimeout())
      Serial.println("Timed out, try again...");
    int16_t err = easyvr.getError();
    if (err >= 0)
    {
      Serial.print("Error ");
      Serial.println(err, HEX);
    }
  }
}

void action()
{
    switch (group)
    {
    case GROUP_0:
      switch (idx)
      {
      case G0_HELLO:
        // write your action code here
        // group = GROUP_X; <-- or jump to another group X for composite commands
        break;
      }
      break;
    case GROUP_1:
      switch (idx)
      {
      case G1_LIGHT_ON:
        digitalWrite(LED,HIGH);
        // write your action code here
        // group = GROUP_X; <-- or jump to another group X for composite commands
        break;
      case G1_LIGHT_OFF:
        digitalWrite(LED,LOW);
        // write your action code here
        // group = GROUP_X; <-- or jump to another group X for composite commands
        break;
      }
      break;
    }
}
