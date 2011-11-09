/*
  SOMO-14D Test
  Control a SOMO-14D module to play sounds

  Reference
  http://www.4dsystems.com.au/prod.php?id=73

  Created 20 October 2009
  By Shigeru Kobayashi
 */

const int clockPin = 4;  // the pin number of the clock pin
const int dataPin = 7;  // the pin number of the data pin
const int busy = 3;

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

boolean played = false;

void setup() {
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  pinMode(busy, INPUT);

  digitalWrite(clockPin, HIGH);
  digitalWrite(dataPin, LOW);

  sendCommand(VOLUME_4);
}

void loop() {
  // play "0000.ad4"
//  delay(10000);
//  if(!playing){
//    sendCommand(VOLUME_4);
//  sendCommand(0x0000);
//  playing = true;
//  }
delay(1000);
if(digitalRead(busy) == LOW && !played){
  sendCommand(0x0000);
  played = true;
  delay(50);
}


//  // play "0001.ad4"
//  sendCommand(0x0001);
//  delay(1000);

//  // stop playing
//  sendCommand(STOP);
//  delay(1000);
}

void sendCommand(unsigned int command) {
  // start bit
  digitalWrite(clockPin, LOW);
  delay(2);

  // bit15, bit14, ... bit0
  for (unsigned int mask = 0x8000; mask > 0; mask >>= 1) {
    if (command & mask) {
      digitalWrite(dataPin, HIGH);
    }
    else {
      digitalWrite(dataPin, LOW);
    }
    // clock low
    digitalWrite(clockPin, LOW);
    delayMicroseconds(200);

    // clock high
    digitalWrite(clockPin, HIGH);
    delayMicroseconds(200);
  }

  // stop bit
  delay(2);
}
