#include <Servo.h>
 
#include <SoftwareSerial.h>
#include <SoftEasyTransfer.h>
#include <EasyTransfer.h>
EasyTransfer ET;
 
//Setup Variables for smoothing of incoming values
int lastThrottle =-999;
int lastYaw = -999;
int lastPitch = -999;
int lastRoll = -999;
int throttleCount = 0;
int yawCount = 0;
int pitchCount = 0;
int rollCount = 0;

struct DATA_STRUCTURE{
int throttleIn;
int yawIn;
int pitchIn;
int rollIn;
};

//The aeroquad takes values just like a servo
Servo throttle;
Servo pitch;
Servo yaw;
Servo roll;
Servo aux;
 
 
DATA_STRUCTURE myData;
void setup()
{
  throttle.attach(9);
  roll.attach(10);
  pitch.attach(11);
  yaw.attach(6);
  aux.attach(5);
 
 
  Serial.begin(57600);
  ET.begin(details(myData), &Serial);
}

void loop()
{
//Always write aux as 1000
aux.writeMicroseconds(1000);
if(ET.receiveData())
{
  //The smoothing process works in this manner: 
  //If the last value received is the default -999, set it to the read value
  //If the read value is 200 more and less than the last value, discard it as it is a spike in data. Instead, make the read value equal to the last value
  //If the read value is within the range of the last value + or - 4 and has repeated at least 10 times, a hand has most likely been lost within the Arduino sketch. In this case, set the value to its default
  //Finally, if all else fails everything is fine and just set the last value to the read value.
  //This is done for each of the four channels
   if(lastThrottle==-999)
   {
     throttleCount = 0;
     lastThrottle=myData.throttleIn;
   }
   else if(myData.throttleIn >= lastThrottle+200  || myData.throttleIn <=lastThrottle-200)
   {
     throttleCount = 0;
     myData.throttleIn = lastThrottle;
   }
   else if(myData.throttleIn <= lastThrottle+4 && myData.throttleIn >= lastThrottle-4)
   {
     throttleCount++;
     if(throttleCount>=10)
     {
       myData.throttleIn = 1250;
     }
   }
   else
   {
     throttleCount = 0;
     lastThrottle = myData.throttleIn;
   }
   throttle.writeMicroseconds(myData.throttleIn); 

  
   
   
   if(lastYaw==-999)
   {
     yawCount = 0;
     lastYaw=myData.yawIn;
   }
   else if(myData.yawIn >= lastYaw+200  || myData.yawIn <=lastYaw-200)
   {
     yawCount = 0;
     myData.yawIn = lastYaw;
   }
   else if(myData.yawIn <= lastYaw+4 && myData.yawIn >= lastYaw-4)
   {
     yawCount++;
     if(yawCount>=10)
     {
       myData.yawIn = 1500;
     }
   }
   else
   {
     yawCount = 0;
     lastYaw = myData.yawIn;
   }
   yaw.writeMicroseconds(myData.yawIn);
   
   
   if(lastPitch==-999)
   {
     pitchCount = 0;
     lastPitch = myData.pitchIn;
   }
   else if(myData.pitchIn >= lastPitch+200 || myData.pitchIn <= lastPitch-200)
   {
     pitchCount = 0;
     myData.pitchIn = lastPitch;
   }
   else if(myData.pitchIn <= lastPitch+4 && myData.pitchIn >= lastPitch-4)
   {
     pitchCount++;
     if(pitchCount>=10)
     {
       myData.pitchIn = 1500;
     }
   }
   else
   {
     pitchCount = 0;
     lastPitch = myData.pitchIn;
   }
   pitch.writeMicroseconds(myData.pitchIn);
  
   

   if(lastRoll==-999)
   {
     rollCount = 0;
     lastRoll = myData.rollIn;
   }
   else if(myData.rollIn >= lastRoll+200 || myData.rollIn <= lastRoll-200)
   {
     rollCount = 0;
     myData.rollIn = lastRoll;
   }
   else if(myData.rollIn <= lastRoll+4 && myData.rollIn >= lastRoll-4)
   {
     rollCount++;
     if(rollCount>=10)
     {
       myData.rollIn = 1500;
     }
   }
   else
   {
     rollCount = 0;
     lastRoll = myData.rollIn;
   }
   roll.writeMicroseconds(myData.rollIn);
   
//   writeData();
}
else
{
  
}
delay(20);
}

//Method for printing the values to Serial. Its call is commented out as printing to Serial tends to interfer with transfer
void writeData()
{
 Serial.print("Throttle: ");
   Serial.println(myData.throttleIn);
  Serial.print("Yaw: ");
 Serial.println(myData.yawIn);
  Serial.print("Pitch: ");
  Serial.println(myData.pitchIn);
  Serial.print("Roll: ");
  Serial.println(myData.rollIn);
}
