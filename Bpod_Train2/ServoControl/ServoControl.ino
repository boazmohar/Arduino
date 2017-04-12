/* Pole control for behavior rig
 * Boaz Mohar 2016
 * This controls two servo motors that swing a pole into the whisker of the mouse
 * One Servo (Main) has a ploe attached and another (Mask) moves as if it was the oppsite trial type for masking
 * The Servos are in their resting positions as long as 'StimPin' is LOW. When HIGH a beep is sent via BeepPin
 * and the servos move. When StimPin retuens to LOW the servos return to thier home position and there is another beep.
 * Trial identetiy is control vie Serial port when 1 is correct left and 2 is correct right. 
*/

#include <Servo.h>
// globals
const float pi = 3.14159265359;

// for serial communication
char buff[7]; 
int nRead=0; 
int trialType=2; // start with a right trial

// pin assigments
const int StimPin = 3;
const int BeepPin = 4;
const int servoPinMain = 13; // Servo that controls the pole
const int servoPinMask = 12; // Servo that masks the sound - both have to be the same type

// timing
unsigned long startTBeep;
const unsigned long beepDur=300000; 

//Servos
String servoType = "HS81"; // Hi-Tec micro servo 
Servo servoMain;  // create servo object to control a servo
Servo servoMask;  // create servo object to control a servo

//States controlled by the state of 'StimPin' that is high during stimulus presentation
volatile int StartStim=0;
volatile int StopStim=0;
volatile int StartBeep=0;
int OngoingBeep=0;
int OngoingStim=0;
int OngoingStop=0;
int OngoingSine=0;
int OngoingStim2=0;
int OngoingStop2=0;
int OngoingSine2=0;

//default params for servo movment
const float galvoStart=30;
const float centerRight = 60;
const float ampRight = 30;
const float centerLeft = 30;
const float ampLeft = 30;
const float freq = 10;

// params for controling the movemnt
float sineCenter=10;
float sineCenter2=10;
float sineAmp=15;
float sineAmp2=0;
float y = 0;
unsigned long x;
unsigned long startT;
float linearRate=0;
float period = 0;
float startY=15;
float startY2=15;
float y2 = 0;
unsigned long x2;
unsigned long startT2;


void setup() {
  Serial.begin(115200);
  if (servoType == "HS81") {
    servoMain.attach(servoPinMain, 800, 2250);  // attaches the servo 
    servoMask.attach(servoPinMask, 800, 2250);  // attaches the servo 
    //Serial.println("Attached");
  }
  else {
    return;
  }
  y = startY;
  y2 = startY2;
  servoMain.write(startY);  // move to start
  servoMask.write(startY2);  // attaches the servo 
  pinMode(StimPin,INPUT);
  pinMode(BeepPin,OUTPUT);
  digitalWrite(BeepPin,LOW);
  attachInterrupt(digitalPinToInterrupt(StimPin), StimCall, CHANGE);
  linearRate=(sineAmp*10)/(1/freq)/1000000;
  period=(1/freq)*1000000;
  delay(300);
}

void loop() {
   if (Serial.available() != 0) {
    nRead=Serial.readBytes(buff,1);
    if (nRead!=1) {
      return;
    }
    if (buff[0]==int('1')) {
      trialType=1;
    }
    if (buff[0]==int('2')) {
      trialType=2;
    }          
  }
   if (trialType==2) {
     sineCenter=centerRight;
     sineAmp=ampRight;
     sineCenter2=centerLeft;
     sineAmp2=ampLeft;
   } 
   if (trialType==1) {
     sineCenter=centerLeft;
     sineAmp=ampLeft;
     sineCenter2=centerRight;
     sineAmp2=ampRight;
   }
  if (StartStim) {
    startT=micros();
    OngoingStim=1;  
    OngoingStop=0;
    startY=y;
    
    startT2=micros();
    OngoingStim2=1;  
    OngoingStop2=0;
    startY2=y2;
    
    StartStim=0;
  }
 if (StartBeep) {
     StartBeep=0;
     startTBeep=micros();
     OngoingBeep=1;
     digitalWrite(BeepPin,HIGH);
     Serial.println("High");
   }
   
   if (OngoingBeep) {
     if ((micros()-startTBeep)>beepDur) {
       digitalWrite(BeepPin,LOW);
       OngoingBeep=0;
       Serial.println("low");
     }  
   }  
  // move the main motor
  if (OngoingStim) {
    
    if (y>sineCenter && OngoingSine==0) {
      
    
      OngoingSine=1;    
      startT=micros();
    }
    x=micros()-startT;
    if (OngoingSine) {
      y=sin(x/period*pi)*sineAmp+sineCenter;
    } else {
      y=startY+(x*linearRate);
    }
  }
   if (StopStim) {
    startT=micros();
    OngoingStim=0;
    OngoingSine=0;
    OngoingStop=1;
    startY=y;
    startT2=micros();
    OngoingStim2=0;
    OngoingSine2=0;
    OngoingStop2=1;
    startY2=y2;
    StopStim=0;
  }
  if (OngoingStop) {
    if (y<=galvoStart) {
      OngoingStop=0;
      y=galvoStart;
    } else {
    x=micros()-startT;
    y=startY-(x*linearRate);
    }    
  }
  servoMain.write(y);
  
  // Move the mask motor
  if (OngoingStim2) {
    if (y2>sineCenter2 && OngoingSine2==0) {
      OngoingSine2=1;    
      startT2=micros();
    }
    x2=micros()-startT2;
    if (OngoingSine2) {
      y2=sin(x2/period*pi)*sineAmp2+sineCenter2;
    } else {
      y2=startY2+(x2*linearRate);
    }
  }
  if (OngoingStop2) {
    if (y2<=galvoStart) {
      OngoingStop2=0;
      y2=galvoStart;
    } else {
    x2=micros()-startT2;
    y2=startY2-(x2*linearRate);
    }    
  }
  servoMask.write(y2);  
}

void StimCall() {
  //identify transition from current state on StimPin
  if (digitalRead(StimPin)==HIGH) {
    //InFix=0;
    StartStim=1;
    StopStim=0;
    StartBeep=1;
  } else {
    StartStim=0;
    StopStim=1;
    StartBeep=1;
  }
}
