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
float[] leftBuffer;
float[] envelope;
boolean hideContourn = false;
void setup()
{
  size(800, 2700);

  minim = new Minim(this);  
  // 2. Loading an AudioRecordingStream and reading in a buffer at a time.
  //    This second option is available starting with Minim Beta 2.1.0

  AudioRecordingStream stream = minim.loadFileStream("../audios/minho2.mp3", BUFFERSIZE, false);
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
  envelope = new float[TOTALCHUNCKS];
  leftBuffer = new float[TOTALCHUNCKS*BUFFERSIZE];

  //capturando o buffer do audio para a memoria
  //preenchendo continuamente um array com todo o audio
  for (int chunkIdx = 0; chunkIdx < TOTALCHUNCKS; chunkIdx++)
  {   
    //proximo buffer 
    println("Chunk " + chunkIdx);
    println("  Reading...");
    stream.read( buffer );
    for (int i = 0; i < buffer.getChannel(0).length; i++) {
      leftBuffer[ i + BUFFERSIZE * chunkIdx ] = buffer.getChannel(0)[i]; //canal
      buffer.getChannel(0)[i] = 2*buffer.getChannel(0)[i]*buffer.getChannel(0)[i];
    }

    fft.forward( buffer.getChannel(0));
    //for (int i = 0; i < fft.specSize() ; i++) {
    envelope[ chunkIdx ] =sqrt(fft.getBand(0));
    //}
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

  //strokeWeight(1);
  //stroke(100  );
  //beginShape();
  //for (int i = 0; i < leftBuffer.length; i+=step)
  //{  
  //  float y1 = map( i, 0, leftBuffer.length, 0, height);
  //  vertex(leftBuffer[i]*1000, y1);
  //}
  //endShape();




  for (int i = 1; i < envelope.length; i+=step)
  {  
    float y1 = map( i, 0, envelope.length, 0, height);
    noStroke();
    fill(255);
    ellipse(envelope[i]*10, y1, 10, 10);
    stroke(255, 200);
    strokeWeight(1);
    noFill();
    for (int j = (int)-random(1, 10); j < random(1, 10); j++) {
      beginShape(LINES);
      vertex(envelope[i]*10, y1);
      vertex(0, y1+j*15);
      endShape();
    }
  }

  if (!hideContourn) {
    stroke(255);
    strokeWeight(2);
    beginShape();
    for (int i = 0; i < envelope.length; i+=step)
    {  
      float y1 = map( i, 0, envelope.length, 0, height);
      vertex(envelope[i]*10, y1);
    }
    endShape();
  }

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
  float del = (p1.y - p2.y) / (p1.x - p2.x);
  float b = (p2.x * p1.y - p1.x * p2.y)/ (p1.x - p2.x);

  if (p3.y < (del*p3.x + b)) {
    return true;
  } else {
    return false;
  }
}