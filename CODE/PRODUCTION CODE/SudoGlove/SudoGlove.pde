/*************************************************************************
**** SUDOGLOVE CONTROLLER PROGRAM                                       **
**** INFO 4320 Final Project, Spring 2010                               **
**** Cornell University                                                 **
**** Copyright: Jeremy Blum, Joe Ballerini, Alex Garcia, and Tiffany Ng **
**************************************************************************/

//Power Switch
const int pwr_led = 42;

//OPERATIONAL MODE
//When debug mode is set to true, pretty values will be printed to the terminal window (for use in USB mode)
//When debug mode is set to false, values are sent wirelessly to car in proper format (for use in XBEE mode)
const boolean debug = false; //False for normal operation
const boolean debug_map = true; //false to display raw sensor values (0-1024), true to display mapped sensor values (0-255) - only valid in debug mode.

//Turning Integration variables
int old_state_turn = 2; //1 is hand left, 2 is middle, 3 is hand right 
int new_state_turn = 2;
int angle = 127;        //Start in the middle (assumes calibration was sucessful)

//Gyroscope Bias
//Higher values means it it will take more umph to move to that position.
//Raise values if it tends to always go in that direction.
const int left_bias  = 16;
const int right_bias = 10;

//Define the analog input pins for our sensors
const int right_gyro_4Y     = 9;
const int right_gyro_4X     = 10;
const int right_flex_index  = 14;
const int right_flex_middle = 15;  //NOTE: not in use
const int right_force_ring  = 12;
const int right_force_pinky = 13;
const int right_vibra_palm  = 11;
//Define the Analog Ouput Pins (PWM pins) (LEDs)
const int right_LED_green   = 8;
const int right_LED_red     = 9;
const int right_LED_yellow  = 10;

//Define Variables for holding sensor data
int rgy; //Right Gyro Y
int rgx; //Right Gyro X
int rfi; //Right Flex Index
int rfm; //Right Flex Middle
int rfr; //Right Force Ring
int rfp; //Right Force Pinky
int rvp; //Right Vibra Palm

//Equilibrium Values
//NOTE: Gyro Values are set in calibration stage, but declared as globals now.
      int rgy_mid;
      int rgy_low;
      int rgy_high;
      int rgx_mid;
      int rgx_low;
      int rgx_high;
const int rfi_straight = 525;
const int rfi_curled   = 730;      
const int rfr_low      = 1023; 
const int rfr_high     = 600;
const int rfp_low      = 1023;
const int rfp_high     = 700;
const int rvp_low      = 1023;
const int rvp_high     = 400;

//This function will format and print number to be sent over XBee
void print_pretty(int val)
{
  int new_val;
  //All Numbers must range from zero to 255.
  if      (val<0)   new_val = 0;
  else if (val>255) new_val = 255;
  else    new_val = val;
  //Add Leading zeros
  if (new_val < 10)
  {
    Serial.print(0);
    Serial.print(0);
    Serial.print(new_val);
  }
  else if (new_val >= 10 && new_val <100)
  {
    Serial.print(0);
    Serial.print(new_val);
  }
  else Serial.print(new_val);
}

void calibrate_gyro(int y_axis_pin, int x_axis_pin)
{
  //If we are talking to the gyroscope sensors, then equilibrium value is at the middle.
  //We will collect 20 data samples in 2 seconds
  
  //Do some dummy reads first.  This seems to be necessary.
  analogRead(x_axis_pin);
  delay (500); 
  analogRead(y_axis_pin);
  delay(500);
  
  //Read Values and do some average to determine sensor sensor calibration states
  int sumy = 0;
  int sumx = 0;
  for (int i = 0; i<20; i++)
  {
    sumy = sumy + analogRead(y_axis_pin);
    sumx = sumx + analogRead(x_axis_pin);
    delay (100);
  }
  double avgy = round(sumy/20);
  double avgx = round(sumx/20);
  
  rgy_mid = avgy;
  rgy_low = 0;
  rgy_high = avgy*2;
  rgx_mid = avgx;
  rgx_low = 0;
  rgx_high = avgx*2;
}

void setup()
{
  //Set Pin Directions
  pinMode (pwr_led,          OUTPUT);
  pinMode (right_gyro_4Y,     INPUT);
  pinMode (right_gyro_4X,     INPUT);
  pinMode (right_flex_index,  INPUT);  
  pinMode (right_flex_middle, INPUT);
  pinMode (right_force_ring,  INPUT);
  pinMode (right_force_pinky, INPUT);
  pinMode (right_vibra_palm,  INPUT);
  pinMode (right_LED_green,  OUTPUT);
  pinMode (right_LED_red,    OUTPUT);
  pinMode (right_LED_yellow, OUTPUT);
  
  //Turn on Pwr LED
  digitalWrite(pwr_led, HIGH);
  
  //Setup Serial Connection to Computer and Xbee
  Serial.begin (9600);
  
  //PERFORM 1-TIME SENSOR CALIBRATION
  //Warn the User that synchronization will occur by counting down with LEDs.
  digitalWrite(right_LED_red, HIGH);
  delay(500);
  digitalWrite(right_LED_red, LOW);
  digitalWrite(right_LED_yellow,HIGH);
  delay(500);
  digitalWrite(right_LED_yellow,LOW);
  digitalWrite(right_LED_green,HIGH);
  delay(500);
  digitalWrite(right_LED_yellow,HIGH);
  digitalWrite(right_LED_red, HIGH);
  //The User has been warned, and we will now start calibrating 
  calibrate_gyro (right_gyro_4Y, right_gyro_4X);
  //Calibration Has Finished.  Turn off Warning LEDs, and prepare for normal operation
  digitalWrite(right_LED_green, LOW);
  delay(500);
  digitalWrite(right_LED_yellow, LOW);
  delay(500);
  digitalWrite(right_LED_red, LOW);
  delay(500);
  //Go!
  
}

void loop()
{
  //Read 3.3V Sensor Values
  analogReference(EXTERNAL);            //3.3V Reference
  rgy = analogRead(right_gyro_4Y);      //Right Gyroscope Y Axis
  rgx = analogRead(right_gyro_4X);      //Right Gyroscope X Axis
  //Read 5V Sensor Values
  analogReference(DEFAULT);             //5V Reference
  rfi = analogRead(right_flex_index);   //Right Flex Index
  rfm = analogRead(right_flex_middle);  //Right Flex Middle
  //NOTE: Force Sensors have some noise problems, so we will average them
    int sumr = 0;
    int sump = 0;
    for (int i=0; i<10; i++)
    {
      sumr = sumr + analogRead(right_force_ring);   //Right Force Ring
      sump = sump + analogRead(right_force_pinky);  //Right Force Pinky
    }
     rfr = round(sumr/10);//Right Force Ring
     rfp = round(sump/10);//Right Force Pinky
  //NOTE: vibration sensors have some noise problems, so we will average them
    int sumv = 0;
    for (int i=0; i<5; i++)
    {
      sumv = sumv + analogRead(right_vibra_palm);    //Right Vibra Palm  
    }
     rvp = round(sumv/5); //Right Vibra Palm  
  
  //Map Values for Transmission
  int RGX = map(rgx, rgx_low,      rgx_high,   0, 255);
  int RGY = map(rgy, rgy_low,      rgy_high,   0, 255);
  int RFI = map(rfi, rfi_straight, rfi_curled, 0, 255);
  int RFR = map(rfr, rfr_low,      rfr_high,   0, 255);
  int RFP = map(rfp, rfp_low,      rfp_high,   0, 255);
  int RVP = map(rvp, rvp_low,      rvp_high,   0, 255);
  
  //Corrects for a Sensor Crossover Problem
  if(RFR > 0)   RFP = RFP - RFR/5;
  //if(RGY > (127+20) || RGY < (127-20)) RVP = RVP - RGY/5;
  //else if(RGX > (127+20) || RGX < (127-20)) RVP = RVP - RGX/5;

  //We integrate data from the Y acceleration to determine a rough position vector  
  //What is the current Turning State?
  if      (RGY > (127-left_bias) && RGY < (127+right_bias)  && old_state_turn == 1) new_state_turn = 1;
  else if (RGY > (127-left_bias) && RGY < (127+right_bias)  && old_state_turn == 2) new_state_turn = 2;
  else if (RGY > (127-left_bias) && RGY < (127+right_bias)  && old_state_turn == 3) new_state_turn = 3;
  
  else if (RGY >= (127+right_bias) && old_state_turn == 1) new_state_turn = 2;
  else if (RGY >= (127+right_bias) && old_state_turn == 2) new_state_turn = 3;
  else if (RGY >= (127+right_bias) && old_state_turn == 3) new_state_turn = 3;
  
  else if (RGY <= (127-left_bias) && old_state_turn == 1) new_state_turn = 1;
  else if (RGY <= (127-left_bias) && old_state_turn == 2) new_state_turn = 1;
  else if (RGY <= (127-left_bias) && old_state_turn == 3) new_state_turn = 2;
  
  else new_state_turn = 2;

  //Perform Turn Angle Integration
  if (new_state_turn == 1)      //Glove is left
  {
    angle = 0;
    digitalWrite(right_LED_red,    LOW);
    digitalWrite(right_LED_green,  HIGH);
    digitalWrite(right_LED_yellow, LOW);
  }
  else if (new_state_turn == 2) //Glove is in middle 
  {
    angle = 127;
    digitalWrite(right_LED_red,    HIGH);
    digitalWrite(right_LED_green,  LOW);
    digitalWrite(right_LED_yellow, LOW);
  }
  else //Glove is right
  {
    angle = 255;
    digitalWrite(right_LED_red,    LOW);
    digitalWrite(right_LED_green,  LOW);
    digitalWrite(right_LED_yellow, HIGH);
  }

  //Be Ready to get the new state in the next iteration of the loop
  old_state_turn = new_state_turn;

  //SEND OUT DATA...
    //Send data over XBee
  if (debug == false)
  { 
    Serial.print('.');
    print_pretty(RGX);
    print_pretty(angle);
    print_pretty(RFI);
    print_pretty(RFR);
    print_pretty(RFP);
    print_pretty(RVP);
    while (Serial.read() != 'a');
  }
  //Print Mapped Debug Info
  else if (debug == true && debug_map == true)
  {
    print_pretty(RGX);
    Serial.print("    ");
    print_pretty(angle);
    Serial.print("    ");
    print_pretty(RFI);
    Serial.print("    ");
    print_pretty(RFR);
    Serial.print("    ");
    print_pretty(RFP);
    Serial.print("    ");
    print_pretty(RVP);
    Serial.println();
    delay(200);
  }
  //Print Raw debug info
  else if (debug == true && debug_map == false)
  {
    Serial.print(rgx);
    Serial.print("    ");
    Serial.print(rgy);
    Serial.print("    ");
    Serial.print(rfi);
    Serial.print("    ");
    Serial.print(rfr);
    Serial.print("    ");
    Serial.print(rfp);
    Serial.print("    ");
    Serial.print(rvp);
    Serial.println();
    delay(800);
  }
}
