/**
 * This sketch demonstrates two ways to accomplish offline (non-realtime) analysis of an audio file.<br>
 * The first method, which uses an AudioSample, is what you see running.<br>
 * The second method, which uses an AudioRecordingStream and is only available in Minim Beta 2.1.0 and beyond,<br>
 * can be viewed by looking at the offlineAnalysis.pde file.
 * <p>
 * For more information about Minim and additional features, visit http://code.compartmental.net/minim/
 *
 */

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;
import java.util.*; 
import processing.pdf.*;

Minim minim;
Path path;

final static int BUFFERSIZE = 2048;
static int TOTALCHUNCKS;

final static int pw = 800;
final static int ph = 2700;

int step = 20;
boolean savePDF = false;
float[] envelope;
boolean hideContourn = false;
void setup()
{
  size(800, 2700);

  minim = new Minim(this);  
  // 2. Loading an AudioRecordingStream and reading in a buffer at a time.
  //    This second option is available starting with Minim Beta 2.1.0

  AudioRecordingStream stream = minim.loadFileStream("../audios/teste.mp3", BUFFERSIZE, false);
  //captura o audio para dentro do buffer
  stream.play();

  FFT fft = new FFT( BUFFERSIZE, stream.getFormat().getSampleRate() );
  fft.window(FFT.HAMMING);

  MultiChannelBuffer buffer = new MultiChannelBuffer(BUFFERSIZE, stream.getFormat().getChannels());

  int totalSamples = int( (stream.getMillisecondLength() / 1000.0) * stream.getFormat().getSampleRate() );
  TOTALCHUNCKS = (totalSamples / BUFFERSIZE) + 1;

  background(23, 74, 119);
  stroke(0);
  //smooth();
  path = new Path();
  envelope = new float[TOTALCHUNCKS]; //two channel

  //capturando o buffer do audio para a memoria
  //preenchendo continuamente um array com todo o audio
  for (int chunkIdx = 0; chunkIdx < TOTALCHUNCKS; chunkIdx++)
  {   
    //proximo buffer 
    println("Chunk " + chunkIdx);
    println("  Reading...");
    stream.read( buffer );
    for (int i = 0; i < buffer.getChannel(0).length; i++) {
      buffer.getChannel(0)[i] = 2*buffer.getChannel(0)[i]*buffer.getChannel(0)[i];
    }

    fft.forward( buffer.getChannel(0));
    for (int i = 0; i < 10; i++) {
      envelope[ chunkIdx ] +=sqrt(fft.getBand(i));
    }
    envelope[chunkIdx]*=10;
  }

  noLoop();
}

void draw() {
  if (savePDF) {
    Date d = new Date(); 
    String fName = "image-"+ d.getTime();
    beginRecord(PDF, fName + ".pdf");
  }

  background(23, 74, 119);
  noFill();

  //Draw Envelop points

  if (!hideContourn) {

    pushMatrix();
    translate(width/2, 0);
    for (int i = 0; i < envelope.length; i+=step)
    {  
      float y1 = map( i, 0, envelope.length, 0, height);
      noStroke();
      fill(255);
      ellipse(envelope[i], y1, 10, 10);
      ellipse(-envelope[i], y1, 10, 10);
    }
    popMatrix();

    pushMatrix();
    translate(width/2, 0);

    noFill();
    stroke(255);
    strokeWeight(0.5);
    beginShape();
    for (int i = 0; i < envelope.length; i+=step)
    {  
      float y1 = map( i, 0, envelope.length, 0, height);
      vertex(envelope[i], y1);
    }
    endShape();

    beginShape();
    for (int i = 0; i < envelope.length; i+=step)
    {  
      float y1 = map( i, 0, envelope.length, 0, height);
      vertex(-envelope[i], y1);
    }
    endShape();
    popMatrix();
  }



  //linhas aleatorios entre os pontos
  ArrayList<PVector> randpoints = new ArrayList<PVector>();

  pushMatrix();
  translate(width/2, 0);
  for (int i = 0; i <  envelope.length-step; i+=step)
  {  
    //two points in the envelope
    float y1 = map( i, 0, envelope.length, 0, height);
    float y2 = map( i+step, 0, envelope.length, 0, height);
    float x1 = envelope[i];
    float x2 = envelope[i+step];

    //random points underneath the evelop points
    for (int j = 0; j < 2; j++) {
      float yr = random(y1, y2);   
      float xr = random(0, x2 > x1? x2: x1 ); 

      while (p3isUndertheLine (new PVector (y1, x1), new PVector(y2, x2), new PVector(yr, xr))) {
        xr = random(0, x2 > x1? x2: x1 );
      } 

      randpoints.add(new PVector(xr, yr));
      //stroke(255, 0, 0);
      //strokeWeight(4);
      //point(xr, yr);
    }

    for (int j = 0; j < 2; j++) {
      float yr = random(y1, y2);   
      float xr = random(0, x2 > x1? x2: x1 ); 

      while (p3isUndertheLine (new PVector (y1, x1), new PVector(y2, x2), new PVector(yr, xr))) {
        xr = random(0, x2 > x1? x2: x1 );
      } 
      randpoints.add(new PVector(-xr, yr));
      //stroke(255, 0, 0);
      //strokeWeight(4);
      //point(-xr, yr);
    }
  }

  for (int i = 0; i < randpoints.size(); i++) {
    PVector p1 = (PVector) randpoints.get(i);

    for (int j = i+1; j < randpoints.size(); j++) {
      PVector p2 = (PVector) randpoints.get(j);
      float joinchance = j/randpoints.size() + p2.dist(p1)/500;

      float ymax, ymin;

      if (p1.y > p2.y) {
        ymax = p1.y;
        ymin = p2.y;
      } else {
        ymax = p2.y;
        ymin = p1.y;
      }


      int kmin = 0;
      for (int k = 0; k <  envelope.length; k++) {
        float y1 = map( k, 0, envelope.length, 0, height);
        if (y1 >= ymin) {
          kmin = k;
          break;
        }
      }

      int kmax = envelope.length;
      for (int k = kmin; k <  envelope.length; k++) {
        float y1 = map( k, 0, envelope.length, 0, height);
        if (y1 >= ymax) {
          kmax = k;
          break;
        }
      }
      boolean todraw = true;
      for (int k = kmin; k <= kmax; k+=1) {
        float y1 = map( k, 0, envelope.length, 0, height);
        PVector p3 = new PVector(y1, envelope[k]);

        if (!p3isUndertheLine( new PVector(p1.y, p1.x), new PVector(p2.y, p2.x), p3)) {
          todraw = false;
          break;
        }
      }
      if (todraw) {
        if (joinchance < random(0.4)) {
          strokeWeight(2);
          stroke(p2.dist(p1)*1.25, 100);
          beginShape(LINES);
          vertex(p1.x, p1.y);
          vertex(p2.x, p2.y);
          endShape();
        }
      }
    }
  }


  popMatrix();




  if (savePDF) {
    endRecord();
    exit();
  }
}

void keyPressed() {
  if (key == 's') {
    savePDF = true;
  } else if (key == '=') {
    step+=1;
  } else if (key == 'v') {

    hideContourn = !hideContourn;
  } else if (key == '-') {
    step-=1;
    if (step <=1) {
      step = 1;
    }
  }
  redraw();
}


boolean p3isUndertheLine(PVector p1, PVector p2, PVector p3) {

  if (p1.x == p2.x) {
    //linha vertical
  }
  float y = ((p2.y - p1.y) / (p2.x - p1.x)) * (p3.x - p1.x)+ p1.y;

  if (y < p3.y) {
    return true;
  } else {
    return false;
  }
}