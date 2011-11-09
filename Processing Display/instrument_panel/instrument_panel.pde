//SUDO Glove Instrument Panel!
//Written by Jeremy Blum
//Some code adapted from Trevor Shannon and David Mellis

//VERY IMPORTANT//
//IF CAR IS NOT ON, THEN USE THIS:
int NEXT_TOKEN = 'a';
//IF CAR IS ON TOO, THEN USE THIS:
//int NEXT_TOKEN = 'b';

//Setup Serial Port and tokens
import processing.serial.*;
Serial port;
String COM = "COM7";
int DELIMITER = '.';


//Class to hold the data
class dataset
{
  int x_gyro       = 127;  //Nothing
  int y_gyro       = 127;  //Turning
  int index_flex   = 0;    //Acceleration
  int ring_force   = 0;    //Forward/Reverse
  int pinky_force  = 0;    //Lights, Sirens, Sounds
  int vibra        = 0;    //Horn
}
dataset last_set = new dataset();
dataset current_set = new dataset();


//Size parameters
int win_height = 650;
int win_width = 800;
int graph_height = 550;

//Fonts?
PFont label_font;
PFont small_font;
PFont title_font;

void setup()
{
  //Start Serial Object
  port = new Serial(this, COM, 9600);
  
  //Window size
  size(win_width,win_height);
  String first_valid_data;
  //Ask for data
  port.write(NEXT_TOKEN);
  //sync up
  while (port.readStringUntil(DELIMITER) == null);
  //request more data
  port.write(NEXT_TOKEN);
  //process
  while((first_valid_data = port.readStringUntil(DELIMITER)) == null);
  parse_data(first_valid_data);
  //request more data
  port.write(NEXT_TOKEN);
  //clear screen;
  background(0);
  
  //Configure fonts
  label_font = loadFont("AgencyFB-Bold-30.vlw");
  small_font = loadFont("ArialUnicodeMS-15.vlw");
  title_font = loadFont("AgencyFB-Reg-40.vlw");
  
  //print URL
  textFont(title_font, 40);
  textAlign(CENTER);
  text("http://sudoglove.jeremyblum.com", 475, 600);
  
  //Draw Accel Container
    rectMode(CORNERS); // Spec rect by IDing two corner coordinates
    stroke(255); //put lines around stuff
    fill(0,0,0);
    rect(50,graph_height,150,40);
  //Draw Lights and Sounds Containers
    ellipse(500, 100, 50, 50);
    ellipse(600, 100, 50, 50);
    ellipse(700, 100, 50, 50);
}

void draw()
{
  String current_data = port.readStringUntil(DELIMITER);
  if (current_data != null)
  {
    port.write(NEXT_TOKEN);
    parse_data(current_data);
    
    
    
    //ACCELERATION
    //Draw the Colored Part
    if (last_set.index_flex<=current_set.index_flex)
    {
      fill(255, 0 , 0);
      rect(50,graph_height - current_set.index_flex,150,graph_height);
    }
    //Draw the Black Part
    else
    {
      fill(0, 0 , 0);
      rect(50,40,150, graph_height-current_set.index_flex);
    }
    fill(255, 255 , 255);
    textFont(label_font, 30);
    textAlign(CENTER);
    text("acceleration", 100, 600);
    
    //DIRECTION
    fill(255, 255 , 255);
    textFont(label_font, 30);
    textAlign(CENTER);
    text("direction", 300, 50);
    textFont(small_font, 15);
    text("reverse", 250, 150);
    text("forward", 350, 150);
    ellipseMode(CENTER); // Center Circle at coordinates
    //Reverse
    if (current_set.ring_force >= 100)
    {
      fill(255, 0 , 0);
      ellipse(250, 100, 50, 50);
      fill(0, 0, 0);
      ellipse(350, 100, 50, 50);
    }
    //Foward
    else
    {
      fill(0, 0 , 0);
      ellipse(250, 100, 50, 50);
      fill(0, 255, 0);
      ellipse(350, 100, 50, 50);
    }
    
    //LIGHTS AND SIRENS
    fill(255, 255 , 255);
    textFont(label_font, 30);
    textAlign(CENTER);
    text("lights and sirens", 600, 50);
    textFont(small_font, 15);
    text("headlights", 500, 150);
    text("flashing lights", 600, 150);
    text("siren sounds", 700, 150);
    ellipseMode(CENTER); // Center Circle at coordinates
    //headlights
    if (current_set.pinky_force >= 30)
    {
      fill(255, 255 , 255);
      ellipse(500, 100, 50, 50);
    }
    else
    {
      fill(0, 0 , 0);
      ellipse(500, 100, 50, 50);
    }
    //siren lights
    if (current_set.pinky_force >= 80)
    {
      fill(165, 165 , 255);
      ellipse(600, 100, 50, 50);
    }
    else
    {
      fill(0, 0 , 0);
      ellipse(600, 100, 50, 50);
    }
    //siren lights
    if (current_set.pinky_force >= 160)
    {
      fill(50, 50 , 255);
      ellipse(700, 100, 50, 50);
    }
    else
    {
      fill(0, 0 , 0);
      ellipse(700, 100, 50, 50);
    }
    
    //TURNING
    fill(255, 255 , 255);
    textFont(label_font, 30);
    textAlign(CENTER);
    text("steering",475, 250);
    textFont(small_font, 15);
    text("left", 375, 350);
    text("straight", 475, 350);
    text("right", 575, 350);
    ellipseMode(CENTER); // Center Circle at coordinates
    //left
    if (current_set.y_gyro == 0)
    {
      fill(0, 255 , 0);
      ellipse(375, 300, 50, 50);
      fill(0, 0 , 0);
      ellipse(475, 300, 50, 50);
      ellipse(575, 300, 50, 50);
    }
    //straight
    else if (current_set.y_gyro == 127)
    {
      fill(255, 0 , 0);
      ellipse(475, 300, 50, 50);
      fill(0, 0 , 0);
      ellipse(375, 300, 50, 50);
      ellipse(575, 300, 50, 50);
    }
    //right
    else
    {
      fill(255, 255 , 0);
      ellipse(575, 300, 50, 50);
      fill(0, 0 , 0);
      ellipse(375, 300, 50, 50);
      ellipse(475, 300, 50, 50);
    } 

    //HORN
    fill(255, 255 , 255);
    textFont(label_font, 30);
    textAlign(CENTER);
    text("horn",475, 450);
    ellipseMode(CENTER); // Center Circle at coordinates
    //horn
    if (current_set.vibra > 200)
    {
      fill(255, 0 , 0);
      ellipse(475, 500, 50, 50);
    }
    else
    {
      fill(0, 0 , 0);
      ellipse(475, 500, 50, 50);
    }
    
  }
}

void parse_data(String buff)
{
  //Don't forget the previous values!
  last_set.x_gyro       = current_set.x_gyro;
  last_set.y_gyro       = current_set.y_gyro;
  last_set.index_flex   = current_set.index_flex;
  last_set.ring_force   = current_set.ring_force;
  last_set.pinky_force  = current_set.pinky_force;
  last_set.vibra        = current_set.vibra;
  
  current_set.x_gyro = int(buff.substring(0,3));
  current_set.y_gyro = int(buff.substring(3,6));
  current_set.index_flex = int(buff.substring(6,9))*2;
  current_set.ring_force = int(buff.substring(9,12));
  current_set.pinky_force = int(buff.substring(12,15));
  current_set.vibra = int(buff.substring(15,18));
}
