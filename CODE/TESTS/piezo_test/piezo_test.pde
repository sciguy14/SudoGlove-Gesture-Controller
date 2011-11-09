int piezoPin1 = 0;
int piezoVal1 = 0;
int mapVal1 = 0;

void setup()
{
  Serial.begin(9600);
}

void loop()
{
  piezoVal1 = analogRead(piezoPin1);
  mapVal1   = map(piezoVal1, 0, 1023, 0, 10);
  Serial.println(piezoVal1);
  delay(100);
}
