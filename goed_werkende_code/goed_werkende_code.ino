
#define PIN_NUM 3
int  data[PIN_NUM]; //data array
char dataID[PIN_NUM] = {'A','B','C'}; //data label
int trigPin[PIN_NUM]={2,9,6};
int echoPin[PIN_NUM]={3,10,7};
int sampleRate = 500;

long timer = micros();
void setup() {
  Serial.begin (115200);
 for (int i = 0 ; i < PIN_NUM ; i++) {
 
 pinMode(trigPin[i], OUTPUT);
  pinMode(echoPin[i], INPUT);

}
}

void loop() {
 
  if (micros() - timer >= 1000000/sampleRate) { //Timer: send sensor data in every 10ms
    timer = micros();
      for (int i = 0 ; i < PIN_NUM ; i++) {
        long duration[i], distance[i];
  digitalWrite(trigPin[i], LOW);  
  delayMicroseconds(2); 
  digitalWrite(trigPin[i], HIGH);
  delayMicroseconds(10); 
  digitalWrite(trigPin[i], LOW);
  duration[i] = pulseIn(echoPin[i], HIGH);
  distance[i] = (duration[i]/2) / 29.1;
   if (distance[i] >= 500 || distance[i] <= 0){
    Serial.println("Out of range");
   }
    else{
  data[i]= distance[i];
delay(10);
      sendDataToProcessing(dataID[i], data[i]);
}
}
}
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}
