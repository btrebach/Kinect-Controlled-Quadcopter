/* Kinect-Quad Project 
 *
 * Modified Version of the "Hands" sketch from the OpenNI Library for Processing
 *
 * --------------------------------------------------------------------------
 * SimpleOpenNI Hands3d Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect 2 library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/
 * date:  12/12/2012 (m/d/y)
 * ----------------------------------------------------------------------------
 * This demos shows how to use the gesture/hand generator.
 * It's not the most reliable yet, a two hands example will follow
 * ----------------------------------------------------------------------------
 */

import java.util.Map;
import java.util.Iterator;

import SimpleOpenNI.*;
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
Serial serial;

boolean armed = false;
boolean control = false;

int pitch = 0;
int roll = 0;
int yaw = 0;
int throttle = 0;
int throttlePin = 11;
int yawPin = 10;
int pitchPin = 9;
int rollPin = 6; 

int handsTracking = 0;
int handCount = 0;

// Max Values
int throttleMax = 0;
int yawMax = 0;
int pitchMax = 0;
int rollMax = 0;

// Min values
int throttleMin = 0;
int yawMin = 0;
int pitchMin = 0;
int rollMin = 0;

SimpleOpenNI context;
int handVecListSize = 20;
Map<Integer, ArrayList<PVector>>  handPathList = new HashMap<Integer, ArrayList<PVector>>();
color[]       userClr = new color[] { 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};



void setup()
{
  //  frameRate(200);
  size(640, 480);

  arduino = new Arduino(this, Arduino.list()[0], 57600);

  arduino.pinMode(throttlePin, arduino.OUTPUT);
  arduino.pinMode(yawPin, arduino.OUTPUT);
  arduino.pinMode(pitchPin, arduino.OUTPUT);
  arduino.pinMode(rollPin, arduino.OUTPUT);


  context = new SimpleOpenNI(this);
  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }   

  // enable depthMap generation 
  context.enableDepth();

  // disable mirror
  context.setMirror(true);

  // enable hands + gesture generation
  //context.enableGesture();
  context.enableHand();
  context.startGesture(SimpleOpenNI.GESTURE_WAVE);

  // set how smooth the hand capturing should be
  //context.setSmoothingHands(.5);
}

void draw()
{
  // update the cam
  context.update();

  image(context.depthImage(), 0, 0);

  // draw the tracked hands
  if (handPathList.size() > 0)  
  {    
    Iterator itr = handPathList.entrySet().iterator();     
    while (itr.hasNext ())
    {
      Map.Entry mapEntry = (Map.Entry)itr.next(); 
      int handId =  (Integer)mapEntry.getKey();
      ArrayList<PVector> vecList = (ArrayList<PVector>)mapEntry.getValue();
      PVector p;
      PVector p2d = new PVector();

      stroke(userClr[ (handId - 1) % userClr.length ]);
      noFill(); 
      strokeWeight(1);        
      Iterator itrVec = vecList.iterator(); 
      beginShape();
      while ( itrVec.hasNext () ) 
      { 
        p = (PVector) itrVec.next(); 

        context.convertRealWorldToProjective(p, p2d);
        vertex(p2d.x, p2d.y);
      }
      endShape();   

      stroke(userClr[ (handId - 1) % userClr.length ]);
      strokeWeight(4);
      p = vecList.get(0);
      context.convertRealWorldToProjective(p, p2d);
      point(p2d.x, p2d.y);
    }
  }
}


// -----------------------------------------------------------------
// hand events

void onNewHand(SimpleOpenNI curContext, int handId, PVector pos)
{
  handCount++;
  handsTracking++;
  println("Now Tracking Hand " + handId);

  if (handsTracking == 2) 
  { 
    control = true;
  }

  ArrayList<PVector> vecList = new ArrayList<PVector>();
  vecList.add(pos);

  handPathList.put(handId, vecList);
}

void onTrackedHand(SimpleOpenNI curContext, int handId, PVector pos)
{
  //  println("Hand " + handId + " Position: " + pos);


  // Take Control of Quad
  if (handsTracking == 2) 
  {
    control = true;
  }

  ////  // Assign Values 
  if (control) 
  {
    if (handId == handCount)  // left hand
    {
      println("left");
      throttle = int(map(pos.y, -600, 950, 0, 255));
      arduino.analogWrite(throttlePin, throttle); // send new throttle
      println("throttle = " + throttle);

      yaw = int(map(pos.x, -600, 950, 0, 255));
      arduino.analogWrite(yawPin, yaw);  // send new yaw
      println("yaw = " + yaw);
    } 
    else if (handId < handCount) // right hand
    {
      println("right");
      pitch = int(map(pos.y, -600, 950, 0, 255));
      arduino.analogWrite(pitchPin, pitch);    // send new throttle
      println("pitch = " + pitch);

      roll = int(map(pos.x, -950, 950, 0, 255));
      arduino.analogWrite(rollPin, roll); // send new roll
      println("roll = " + roll);
    }
  }

  //    if (roll < yaw) // hands are switched - set right hand
  //    {
  //      pitch = int(map(pos.y, -600, 950, 0, 255));
  //      roll = int(map(pos.x, -950, 950, 0, 255));
  //    } 
  //    if (roll > yaw) // set left hand
  //    {
  //      throttle = int(map(pos.y, -600, 950, 0, 255));
  //      yaw = int(map(pos.x, -950, 950, 0, 255));
  //    }
  //    
  //  }

  //      arduino.analogWrite(throttlePin, throttle);
  //      arduino.analogWrite(yawPin, yaw);
  //      arduino.analogWrite(pitchPin, pitch);
  //      arduino.analogWrite(rollPin, roll);



  ArrayList<PVector> vecList = handPathList.get(handId);
  if (vecList != null)
  {
    vecList.add(0, pos);
    if (vecList.size() >= handVecListSize)
      // remove the last point 
      vecList.remove(vecList.size()-1);
  }
}

void onLostHand(SimpleOpenNI curContext, int handId)
{
  handsTracking--;
  if (handsTracking < 2) 
  { 
    control = false;
  }
  println("Lost Hand " + handId);
  handPathList.remove(handId);
}

// -----------------------------------------------------------------
// gesture events

void onCompletedGesture(SimpleOpenNI curContext, int gestureType, PVector pos)
{
  println("onCompletedGesture - gestureType: " + gestureType + ", pos: " + pos);

  int handId = context.startTrackingHand(pos);
  println("hands tracked: " + handId);
}

// -----------------------------------------------------------------
// Keyboard event
void keyPressed()
{

  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  case '1':
    context.setMirror(true);
    break;
  case '2':
    context.setMirror(false);
    break;
  }
}

