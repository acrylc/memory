import processing.video.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import gab.opencv.*;
import java.awt.*;

import muthesius.net.*;
import org.webbitserver.*;
import jcifs.util.Base64;

import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;


WebSocketP5 socket;
Capture cam;
OpenCV opencv;
PImage dst;

// Variables for communicating with servos
Serial port; // The serial port

//Variables for keeping track of the current servo positions.
char servoTiltPosition = 90;
char servoPanPosition = 90;
//The pan/tilt servo ids for the Arduino serial command interface.
char tiltChannel = 0;
char panChannel = 1;

//These variables hold the x and y location for the middle of the detected face.
int midFaceY=0;
int midFaceX=0;

//The variables correspond to the middle of the screen, and will be compared to the midFace values
int midScreenY;// = (height/2);
int midScreenX;// = (width/2);
int midScreenWindow = 10;  //This is the acceptable 'error' for the center of the screen. 


void setup() {
  size( 320, 180 );
  midScreenY = height/2;
  midScreenX = width/2;
  socket = new WebSocketP5( this, 8080 );
        String[] cameras = Capture.list();

         if (cameras.length == 0) {
          println("There are no cameras available for capture.");
          exit();
        } else {
          println("Available cameras:");
//          for (int i = 0; i < cameras.length; i++) {
//            println(i+":"+cameras[i]);
//          }
          
          // The camera can be initialized directly using an 
          // element from the array returned by list():
  cam = new Capture(this, 640/2, 480/2);
          cam.start();     
        }
    
  size(640, 480);
  opencv = new OpenCV(this, 640/2, 480/2);
      opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

}

byte[] int2byte(int[]src) {
  int srcLength = src.length;
  byte[]dst = new byte[srcLength << 2];
    
  for (int i=0; i<srcLength; i++) {
    int x = src[i];
    int j = i << 2;
    dst[j++] = (byte) (( x >>> 0 ) & 0xff);           
    dst[j++] = (byte) (( x >>> 8 ) & 0xff);
    dst[j++] = (byte) (( x >>> 16 ) & 0xff);
    dst[j++] = (byte) (( x >>> 24 ) & 0xff);
  }
  return dst;
}

void broadcast() {
  BufferedImage buffimg = new BufferedImage( width, height, BufferedImage.TYPE_INT_RGB);
  loadPixels();
  buffimg.setRGB( 0, 0, width, height, pixels, 0, width );
  
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  try {
      ImageIO.write( buffimg, "jpg", baos );
        
    } catch( IOException ioe ) {
  }
  
  String b64image = Base64.encode( baos.toByteArray() );
  socket.broadcast( b64image );
}

void draw() {
  if (cam.available()) {
    cam.read();
    opencv.loadImage(cam);
    opencv.findCannyEdges(20,75);
    dst = opencv.getSnapshot();
    
    image(dst,0,0);
  }
  
  broadcast();
  trackFaceAndDisplay();
}

void stop(){
  socket.stop();
}

void websocketOnMessage(WebSocketConnection con, String msg){
  println(msg);
}

void websocketOnOpen(WebSocketConnection con){
  println("A client joined");
}

void websocketOnClosed(WebSocketConnection con){
  println("A client left");
  
}



// Face tracking functions

void captureEvent(Capture c) {
  c.read();
}

void trackFaceAndDisplay(){
    scale(2);
  opencv.loadImage(cam);

  image(cam, 0, 0 );

  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  Rectangle[] faces = opencv.detect();
  println(faces.length);

  for (int i = 0; i < faces.length; i++) {
    println(faces[i].x + "," + faces[i].y);
    rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
  }
}

