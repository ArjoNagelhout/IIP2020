#define PIN_NUM 3
int  data[PIN_NUM]; //data array
char dataID[PIN_NUM] = {'A', 'B', 'C'}; //data label
int trigPin[PIN_NUM] = {14, 16, 18};
int echoPin[PIN_NUM] = {13, 15, 17};
int sampleRate = 2000;

int minDistance = 2; // in cm
int maxDistance = 100; // in cm

long timer = micros();
void setup() {
  Serial.begin (115200);
  for (int i = 0 ; i < PIN_NUM ; i++) {

    pinMode(trigPin[i], OUTPUT);
    pinMode(echoPin[i], INPUT);

  }
}

void loop() {

  if (micros() - timer >= 1000000 / sampleRate) {
    timer = micros();
    for (int i = 0 ; i < PIN_NUM ; i++) {
      long duration, distance;
      digitalWrite(trigPin[i], LOW);
      delayMicroseconds(2);
      digitalWrite(trigPin[i], HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPin[i], LOW);
      duration = pulseIn(echoPin[i], HIGH);
      distance = (duration / 2) / 29.1; // Gets the distance in cm
      distance = map(distance, minDistance, maxDistance, 0, 1024);
      

      if ((distance >= 0) && (distance <= 1024)) {
        data[i] = distance;
        sendDataToProcessing(dataID[i], data[i]);
      }
    }
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}
