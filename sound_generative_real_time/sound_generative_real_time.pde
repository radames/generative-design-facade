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
AudioSample som;
FFT fft;
WaveformRenderer waveform;

final static int BUFFERSIZE = 2048;
static int TOTALCHUNCKS;

final static int pw = 800;
final static int ph = 2700;

int step = 10;
float amp = 4; //amplitude
boolean savePDF = false;
float[] leftBuffer;
float[] envelope;
float[] buffer;
boolean hideContourn = false;

void setup()
{
  size(800, 2700);

  minim = new Minim(this);  
  // 2. Loading an AudioRecordingStream and reading in a buffer at a time.
  //    This second option is available starting with Minim Beta 2.1.0

  som = minim.loadSample("minho2.mp3", BUFFERSIZE);


  fft = new FFT( BUFFERSIZE, som.getFormat().getSampleRate() );
  buffer = new float[BUFFERSIZE];
  fft.window(FFT.HAMMING);


  int totalSamples = int( (som.length() / 1000.0) * som.getFormat().getSampleRate() );
  TOTALCHUNCKS = (totalSamples / BUFFERSIZE) + 1;

  background(23, 74, 119);
  stroke(0);
  smooth();
  path = new Path();
  envelope = new float[TOTALCHUNCKS];
  //leftBuffer = new float[TOTALCHUNCKS*BUFFERSIZE];
  //leftBuffer = som.getChannel(1);


  // float[] leftChannel = jingle.getChannel();

  som.trigger();
  waveform = new WaveformRenderer();
  som.addListener( waveform );
}
int chunkIdx = 0;

void draw() {

  if (savePDF) {
    beginRecord(PDF, "image.pdf");
  }

  background(23, 74, 119);
  noFill();

  if (!hideContourn) {

    pushMatrix();
    translate(width/2, 0);
    for (int i = 0; i < envelope.length; i+=step)
    {  
      float y1 = map( i, 0, envelope.length, 0, height);
      noStroke();
      fill(255);
      ellipse(envelope[i]*amp, y1, 10, 10);
      ellipse(-envelope[i]*amp, y1, 10, 10);
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
      vertex(envelope[i]*amp, y1);
    }
    endShape();

    beginShape();
    for (int i = 0; i < envelope.length; i+=step)
    {  
      float y1 = map( i, 0, envelope.length, 0, height);
      vertex(-envelope[i]*amp, y1);
    }
    endShape();

    popMatrix();
  }


  waveform.draw();


  if (savePDF) {
    endRecord();
    exit();
  }
}

void keyPressed() {
  if (key == 's') {
    savePDF = true;
  }
  else if (key == 'v') {

    hideContourn = !hideContourn;
  }

  redraw();
}



class WaveformRenderer implements AudioListener
{
  private float[] left;
  private float[] right;

  WaveformRenderer()
  {
    left = null; 
    right = null;
  }

  synchronized void samples(float[] samp)
  {
    left = samp;
  }

  synchronized void samples(float[] sampL, float[] sampR)
  {
    left = sampL;
    right = sampR;
  }

  synchronized void draw()
  {



    // we've got a stereo signal if right or left are not null
    if ( left != null && right != null )
    {

      noFill();
      stroke(255);
      beginShape();
      for ( int i = 0; i < left.length; i++ )
      {
        vertex(i, height/ 2+ left[i]*50);
      }
      endShape();
      beginShape();
      for ( int i = 0; i < right.length; i++ )
      {
        vertex(i, 3*(height/4) + right[i]*50);
      }
      endShape();
    }
    else if ( left != null )
    {

      for (int i = 0; i < left.length; i++) {
        //leftBuffer[ i + BUFFERSIZE * chunkIdx ] = left[i]; //canal
        buffer[i] = 2*left[i]*left[i];
      }

      fft.forward( buffer);

      if(chunkIdx >= TOTALCHUNCKS){
        som.removeListener( waveform );
        
      }
      
      
      for (int i = 0; i < 5; i++) {
        envelope[ chunkIdx ] +=sqrt(fft.getBand(i));
      }
      
      
       chunkIdx++;

      

      noFill();
      stroke(255);
      beginShape();
      for ( int i = 0; i < left.length; i++ )
      {
        vertex(i, height/2 + left[i]*50);
      }
      endShape();
    }
  }
}