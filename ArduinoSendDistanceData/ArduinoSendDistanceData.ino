#define PIN_NUM 3
int  data[PIN_NUM]; //data array

char dataID[PIN_NUM] = {'A', 'B', 'C'}; //data label
int trigPin[PIN_NUM] = {14, 16, 18};
int echoPin[PIN_NUM] = {13, 15, 17};
int sampleRate;
int sampleDuration;

int minDistance = 2; // in cm
int maxDistance = 50; // in cm
int maxChange = 100;
int changeCount[PIN_NUM];
int maxChangeCount = 0;

long timer = micros();
void setup() {
  Serial.begin (115200);
  for (int i = 0 ; i < PIN_NUM ; i++) {

    pinMode(trigPin[i], OUTPUT);
    pinMode(echoPin[i], INPUT);

  }

  //speed_of_sound = 340 m/s
  //duration = maxDistance / speed_of_sound (in seconds)
  //duration = (maxDistance / 100) / 340 (in seconds)
  //duration = (maxDistance / 100) / 340 * 1000000 (in micro seconds)
  //totalduration = 3*2*((maxDistance/100)/340*1000000) (in micro seconds)

  sampleDuration = 65*maxDistance; // Simplified equation
  //sampleRate = 1000000 / (sampleDuration*3); // Sample rate for three sensors
}

void loop() {

  if (micros() - timer >= sampleDuration*PIN_NUM) { // alternative to 1000000 / sampleRate
    timer = micros();
    for (int i = 0 ; i < PIN_NUM ; i++) {
      long duration, distance;
      digitalWrite(trigPin[i], LOW);
      delayMicroseconds(2);
      digitalWrite(trigPin[i], HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPin[i], LOW);
      duration = pulseIn(echoPin[i], HIGH, sampleDuration);
      distance = (duration / 2) / 29.1; // Gets the distance in cm
      distance = map(distance, minDistance, maxDistance, 0, 1024);
      distance = constrain(distance, 0, 1024);

      if (duration != 0) {
        if (abs(data[i]-distance) < maxChange) {
          
          data[i] = distance;
          
          
        } else {
          if (changeCount[i] < maxChangeCount) {
            changeCount[i] += 1;
          } else {
            // Now the data can be changed to the new value
            data[i] = distance;
            changeCount[i] = 0;
            
          }
          
        }
      }
      /*
      if (duration != 0) { 
        data[i] = distance;
      }*/
      
      sendDataToProcessing(dataID[i], data[i]);
      
    }
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}
