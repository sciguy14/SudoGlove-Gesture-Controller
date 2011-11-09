int forcePin1 = 0;    //Analog Pin 0
int forceVal1 = 0;    //Force Value
int mapVal1   = 0;
void setup()
{
  Serial.begin(9600);
}

void loop()
{
  forceVal1 = analogRead(forcePin1);
  mapVal1 = map(forceVal1, 1023, 700, 0, 10); 
  Serial.println(mapVal1);

}
