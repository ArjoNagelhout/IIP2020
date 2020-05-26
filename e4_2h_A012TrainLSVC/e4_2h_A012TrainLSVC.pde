//*********************************************
// Example Code for Interactive Intelligent Products
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************

import papaya.*;
import processing.serial.*;
Serial port; 
PImage screenScan;
PImage screenDelete;
PImage screenPay;
PImage screenLongReceipt;
PImage screenShortReceipt;
PImage product;
PImage selectedProduct;

int currentState = 0; 
int currentProductAmount = 0;
int maxProductAmount = 3;
int currentlySelectedProduct = 0;
int productX = 663;
int productY = 244;
int productHeight = 189;

int currentPrediction = 0; // 0 is left, 1 is right and 2 is select
boolean newIncomingPrediction = false;
boolean firstTime = true;

/*
0: scan
1: delete
2: pay
3: long receipt
4: short receipt

663, 244 locatie product
189 hoogte product
*/

int sensorNum = 3; 
int streamSize = 500;
int[] rawData = new int[sensorNum];
float[][] sensorHist = new float[sensorNum][streamSize]; //history data to show

float[][] diffArray = new float[sensorNum][streamSize]; //diff calculation: substract

float[] modeArray = new float[streamSize]; //To show activated or not
float[][] thldArray = new float[sensorNum][streamSize]; //diff calculation: substract
int activationThld = 60; //The diff threshold of activiation

int windowSize = 60; //The size of data window
float[][] windowArray = new float[sensorNum][windowSize]; //data window collection
boolean b_sampling = false; //flag to keep data collection non-preemptive
int sampleCnt = 0; //counter of samples

//Save
Table csvData;
boolean b_saveCSV = false;
String dataSetName = "DataSetTrain.arff"; 
String[] attrNames = new String[]{"m_x", "sd_x", "label"};
boolean[] attrIsNominal = new boolean[]{false, false, true};
int labelIndex = 0;

float m_x = -1;
float sd_x = -1;
float m_y = -1;
float sd_y = -1;
float m_z = -1;
float sd_z = -1;
boolean bShowInfo = true;

void setup() {
  fullScreen(P2D);
  
  screenScan = loadImage("zelfscanplein-01.png");
  screenDelete = loadImage("zelfscanplein-02.png");
  screenPay = loadImage("zelfscanplein-03.png");
  screenLongReceipt = loadImage("zelfscanplein-04.png");
  screenShortReceipt = loadImage("zelfscanplein-05.png");
  product = loadImage("zelfscanplein-06.png");
  selectedProduct = loadImage("zelfscanplein-07.png");
  
  initSerial();
  loadTrainARFF(dataset="DataSetTrain_v2.arff"); //load a ARFF dataset
  trainLinearSVC(C=64);             //train a SV classifier
  setModelDrawing(unit=2);         //set the model visualization (for 2D features)
  evaluateTrainSet(fold=5, isRegression=false, showEvalDetails=true);  //5-fold cross validation
  saveModel(model="LinearSVC.model"); //save the model
}

void draw() {
  background(255);
  /*
0: scan
1: delete
2: pay
3: long receipt
4: short receipt

663, 244 locatie product
189 hoogte product
*/

  if (newIncomingPrediction) {
    
    
    // Do all the logic here
    if (currentState == 0) {
      // SCAN SCREEN
      if (currentPrediction == 0) {
        // LEFT, delete product
        if (currentProductAmount > 0) {
          currentState = 1;
        }
      } else if (currentPrediction == 2) {
        // SELECT, checkout
        currentState = 2;
      }
    } else if (currentState == 1) {
      // DELETE SCREEN
      if (currentPrediction == 0) {
        // PREVIOUS
        if (currentlySelectedProduct > 0) {
          currentlySelectedProduct -= 1;
        }
      } else if (currentPrediction == 1) {
        // NEXT
        if (currentlySelectedProduct < currentProductAmount-1) {
          currentlySelectedProduct += 1;
        }
      } else if (currentPrediction == 2) {
        // ACTUALLY DELETE
        currentProductAmount -= 1;
        currentState = 0;
      }
    } else if (currentState == 2) {
      // PAY
      if (currentPrediction == 0) {
        // LEFT, korte bon
        currentState = 4;
      } else if (currentPrediction == 1) {
        currentState = 3;
      }
    }
    
    
    newIncomingPrediction = false;
  }

  if (currentState == 0) {
    image(screenScan, 0, 0);
  } else if (currentState == 1) {
    image(screenDelete, 0, 0);
  } else if (currentState == 2) {
    image(screenPay, 0, 0);
  } else if (currentState == 3) {
    image(screenLongReceipt, 0, 0);
  } else if (currentState == 4) {
    image(screenShortReceipt, 0, 0);
  }
  
  if (currentState != 4) {
    for (int i=0; i<currentProductAmount; i++) {
      if ((currentlySelectedProduct == i) && (currentState == 1)) {
        
        image(selectedProduct, productX, productY+productHeight*i);
      } else {
        image(product, productX, productY+productHeight*i);
      }
    }
  }
  


  
  //showInfo("Pred: "+Y,20,20);
  pushStyle();
  fill(0);
  textSize(120);
  textAlign(CENTER, CENTER);
  String display = "";
  if (currentPrediction == 0) {
    display = "<--";
  } else if (currentPrediction == 1) {
    display = "-->";
  } else if (currentPrediction == 2) {
    display = "SELECT";
  }
  text(display, width/5, height/2);
  popStyle();
}

void mousePressed() {
  currentProductAmount = 0;
  currentState = 0;
}

void keyPressed() {
  if (key == 'A' || key == 'a') {
    activationThld = min(activationThld+5, 100);
  }
  if (key == 'Z' || key == 'z') {
    activationThld = max(activationThld-5, 10);
  }
  if (key == 'I' || key == 'i') {
    bShowInfo = (bShowInfo? false:true);
  }
  if (key == ' ') {
    // Add product
    if (currentProductAmount < maxProductAmount) {
      currentProductAmount += 1;
    }
  }
    
}

float diff = 0;
void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  if (inData.charAt(0) == 'A') {
    rawData[0] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[0]), map(rawData[0], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[0])[0] - (sensorHist[0])[1]), diff); //absolute diff
    appendArray(diffArray[0], diff);
    appendArray(thldArray[0], activationThld);
  }
  if (inData.charAt(0) == 'B') {
    rawData[1] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[1]), map(rawData[1], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[1])[0] - (sensorHist[1])[1]), diff); //absolute diff
    appendArray(diffArray[1], diff);
    appendArray(thldArray[1], activationThld);
  }
  if (inData.charAt(0) == 'C') {
    rawData[2] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[2]), map(rawData[2], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[2])[0] - (sensorHist[2])[1]), diff); //absolute diff
    appendArray(diffArray[2], diff);
    appendArray(thldArray[2], activationThld);

    //test activation threshold
    if (diff>activationThld) { 
      appendArray(modeArray, 2); //activate when the absolute diff is beyond the activationThld
      if (b_sampling == false) { //if not sampling
        b_sampling = true; //do sampling
        sampleCnt = 0; //reset the counter
        for (int i = 0; i < sensorNum; i++) {
          for (int j = 0; j < windowSize; j++) {
            (windowArray[i])[j] = 0; //reset the window
          }
        }
      }
    } else { 
      if (b_sampling == true) appendArray(modeArray, 3); //otherwise, deactivate.
      else appendArray(modeArray, -1); //otherwise, deactivate.
    }
    diff = 0;
    if (b_sampling == true) {
      for ( int c = 0; c < sensorNum; c++) {
        appendArray(windowArray[c], rawData[c]); //store the windowed data to history (for visualization)
      }
      ++sampleCnt;
      if (sampleCnt == windowSize) {
        m_x = Descriptive.mean(windowArray[0]); //mean
        sd_x = Descriptive.std(windowArray[0], true); //standard deviation
        m_y = Descriptive.mean(windowArray[1]); //mean
        sd_y = Descriptive.std(windowArray[1], true); //standard deviation
        m_z = Descriptive.mean(windowArray[2]); //mean
        sd_z = Descriptive.std(windowArray[2], true); //standard deviation
        b_sampling = false; //stop sampling if the counter is equal to the window size
        
        // Now it should get the prediction
        float[] X = {m_x, sd_x,m_y, sd_y,m_z, sd_z}; 
        if (firstTime == false) {
          
          String currentPredictionString = getPrediction(X);
          
          if (currentPredictionString.equals("A")) {
            currentPrediction = 0;
          } else if (currentPredictionString.equals("B")) {
            currentPrediction = 1;
          } else if (currentPredictionString.equals("C")) {
            currentPrediction = 2;
          }
          newIncomingPrediction = true;
        } else {
          firstTime = false;
        }
      }
      
    }
  }
  return;
}

//Append a value to a float[] array.
float[] appendArray (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, tempArray, tempArray.length);
  array[0] = _val;
  arrayCopy(tempArray, 0, array, 1, tempArray.length);
  return array;
}

void initSerial() {
  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//MAC: check the printed list
  //String portName = Serial.list()[9];//WINDOWS: check the printed list
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer
}
