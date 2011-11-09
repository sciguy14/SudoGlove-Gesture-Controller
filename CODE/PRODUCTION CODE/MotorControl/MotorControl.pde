/*************************************************************************
**** SUDOGLOVE RC CAR PROGRAM                                           **
**** INFO 4320 Final Project, Spring 2010                               **
**** Cornell University                                                 **
**** Copyright: Jeremy Blum, Joe Ballerini, Alex Garcia, and Tiffany Ng **
**************************************************************************/

unsigned long millis(void);

//H-Bridge Pins
const int mPin1 = 10;
const int mPin2 = 11;
const int mPin3 = 5;
const int mPin4 = 6;

//SOMO pins and constants
const int clk = 14;
const int data = 15;
const int busy = 16;
const unsigned int VOLUME_0 = 0xFFF0;
const unsigned int VOLUME_1 = 0xFFF1;
const unsigned int VOLUME_2 = 0xFFF2;
const unsigned int VOLUME_3 = 0xFFF3;
const unsigned int VOLUME_4 = 0xFFF4;
const unsigned int VOLUME_5 = 0xFFF5;
const unsigned int VOLUME_6 = 0xFFF6;
const unsigned int VOLUME_7 = 0xFFF7;
const unsigned int PLAY_PAUSE = 0xFFFE;
const unsigned int STOP = 0xFFFF;

//Headlights Pin
const int headlight_pin = 12;

//Siren Lights Pins
const int sPin1 = 8;
const int sPin2 = 9;

//Hold Serial commands
char buffer[18];  //There are 6 3-digit commands
const int buffer_len = 18;

//State variables
boolean characterSent = false;
boolean sirenOn = false;
boolean hlightsOn = false;
boolean sounds = false;
boolean leftRight = false;
boolean soundsH = false;

//Sensor Values
int something = 0;
int accel = 0;
int turn = 0;
int sirenNLights = 0;
int honk = 0;
int reverse = 0;

//Threshold values for switching commands
const int headlightsThreshold = 30;   //30
const int sirenLightsThreshold = 80;  //90
const int sirenSoundThreshold = 160;  //200
const int surfaceThreshold = 190;   // 190 for carpet, 150 for hard surface
const int honkThreshold = 200;       
const int reverseThreshold = 100;    

//Clears the buffer coming in from signal
void clearBuffer(){
  for(int i = 0; i < buffer_len; i++){
    buffer[i] = 0;
  }
}

//Send command to SOMO for sounds
void sendCommand(unsigned int command) {
  // start bit
  digitalWrite(clk, LOW);
  delay(2);

  // bit15, bit14, ... bit0
  for (unsigned int mask = 0x8000; mask > 0; mask >>= 1) {
    if (command & mask) {
      digitalWrite(data, HIGH);
    }
    else {
      digitalWrite(data, LOW);
    }
    // clock low
    digitalWrite(clk, LOW);
    delayMicroseconds(200);

    // clock high
    digitalWrite(clk, HIGH);
    delayMicroseconds(200);
  }

  // stop bit
  delay(2);
}

void setup(){
//  //These Pins are Outputs
  pinMode(sPin1, OUTPUT);
  pinMode(sPin2, OUTPUT);
  pinMode(clk,   OUTPUT);
  pinMode(data,  OUTPUT);
  pinMode(busy,  INPUT);
  pinMode(headlight_pin, OUTPUT);
  
  Serial.begin(9600);
  clearBuffer();
  
  //Keep motor off on initialization
  analogWrite(mPin1, 0);
  analogWrite(mPin2, 0);
  analogWrite(mPin3, 0);
  analogWrite(mPin4, 0);  
  
  //Set Default Values for SOMO
  digitalWrite(clk, HIGH);
  digitalWrite(data, LOW);
  sendCommand(VOLUME_4);
  delay(50);
  sendCommand(0x0002);
  delay(50);
  while(digitalRead(busy) == HIGH);
  delay(2000);
  Serial.flush();
}

 
 
void loop(){
  //Sending a character tells the glove unit to deliver more data
  if(!characterSent){
    Serial.print('a'); 
    characterSent = true;
  }
  
  //Get commands
  if(Serial.available()){
    characterSent = false;
    char check = Serial.read();
  
    if(check == '.')
    { 
      for (int i=0; i <buffer_len; i++)
      {
        buffer[i] = Serial.read();
        delay(10);
      }
  
      //Get the data from the XBee Transmission
      char driveTrain[3] = {
        buffer[0], buffer[1], buffer[2]      }; 
      char steering[3] = {
        buffer[3], buffer[4], buffer[5]      };
      char headlights[3] = {
        buffer[6], buffer[7], buffer[8]      };
      char sirenlights[3] = {
        buffer[9], buffer[10], buffer[11]    };
      char sirenSounds[3] = {
        buffer[12], buffer[13], buffer[14]   };
        char horn[3] = {
        buffer[15], buffer[16], buffer[17]   };
  
      //Parse buffer into our sensor values
      something    = 100*(driveTrain[0] - '0') + 10*(driveTrain[1]-'0') + (driveTrain[2]-'0');
      turn         = 100*(steering[0] - '0') + 10*(steering[1]-'0') + (steering[2]-'0');
      accel        = 100*(headlights[0] - '0') + 10*(headlights[1]-'0') + (headlights[2]-'0');
      reverse      = 100*(sirenlights[0] - '0') + 10*(sirenlights[1]-'0') + (sirenlights[2]-'0');
      sirenNLights = 100*(sirenSounds[0] - '0') + 10*(sirenSounds[1]-'0') + (sirenSounds[2]-'0');
      honk         = 100*(horn[0] - '0') + 10*(horn[1]-'0') + (horn[2]-'0');
       
      //Turn on headlights
      if(sirenNLights < headlightsThreshold)
      {
       hlightsOn=false;
       sirenOn=false;
       sounds=false; 
      }
      else if((sirenNLights >= headlightsThreshold) && (sirenNLights < sirenLightsThreshold))
        {
         hlightsOn = true;
         sirenOn=false;
         sounds = false;
        }
      //turn on siren lights by pressing pinky twice as hard
       else if((sirenNLights >= sirenLightsThreshold) && (sirenNLights < sirenSoundThreshold))
        {
         hlightsOn=true;
         sirenOn=true;
         sounds = false;
        }
      //turn on siren sounds by pressing pinky three times as hard
      else if(sirenNLights >= sirenSoundThreshold)
       {
         hlightsOn=true;
         sirenOn=true;
         sounds=true;
       }
       
      // Control Headlights
      if(hlightsOn){
        digitalWrite(headlight_pin, HIGH);
      }else{
        digitalWrite(headlight_pin, LOW);
      }
      
     
     // Control Siren Lights 
     if(sirenOn) {
        if(leftRight) {
          digitalWrite(sPin1, HIGH);
          digitalWrite(sPin2, LOW);
        } 
        else {
          digitalWrite(sPin1, LOW);
          digitalWrite(sPin2, HIGH);
        }
    
        leftRight = !leftRight;
      } else if(!sirenOn){
        digitalWrite(sPin1, LOW);
        digitalWrite(sPin2, LOW);
      }

    
      //Acceleration Commands
      if(accel < surfaceThreshold){
        analogWrite(mPin1, 0);
        analogWrite(mPin2, 0);
      }else{
        if(reverse > reverseThreshold){
          analogWrite(mPin1, 0);
          analogWrite(mPin2, accel);
        } else {
          analogWrite(mPin1, accel);
          analogWrite(mPin2, 0);
        }
      }
      
    
      //Turning Commands
      if(turn <= 77){
        analogWrite(mPin3, 255);
        analogWrite(mPin4, 0);
      } 
      else if(turn >= 178){
        analogWrite(mPin3, 0);
        analogWrite(mPin4, 255);
      } 
      else {//if(turn_digital == 1)
        analogWrite(mPin3, 0);
        analogWrite(mPin4, 0);
      }
    
      
      // Control Honk Sound
      if(honk >= honkThreshold)
       {
        soundsH = true;
       }
       else if(honk < honkThreshold && digitalRead(busy)==LOW)  //don't overlap
       {
        soundsH=false; 
       }
       
       

      // Control Sounds
      if(sounds && digitalRead(busy) == LOW)          //play siren sound
       {
        sendCommand(0x0000);
        delay(50);
       } 
      else if((soundsH) && (digitalRead(busy)==LOW))  //play horn
       {
        sendCommand(0x0001);
        delay(50); 
       }
        else if(!sounds && !soundsH){
        sendCommand(STOP);
        delay(50);
       }
       
    }
  }
}
    

