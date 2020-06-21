// Arjo Nagelhout - 18 oct 2019
// TUe Bachelor Industrial Design year 1 - Q1 From Idea to Design
// 

// Adapted from:
// Daniel Shiffman
// Kinect Point Cloud example

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

import papaya.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;

PFont monospace;


// Kinect Library object
Kinect kinect;
Camera camera;

ParameterList parameterList;
ProductColors productColors;

ArrayList<Product> products;

boolean showImage = false;
boolean coloredPixels = false;
boolean renderPixels = true;
boolean debugInfo = true;
PImage colorImage;

float factor = 200;
boolean lostTracking = true;
boolean canLoseTracking = false;

String action = "calibrate";
boolean actionChange = true;
/*
"calibrate"
"collect_data"
"train_model"
"demo"

*/

int sensorNum = 3; 
int streamSize = 500;
int[] rawData = new int[sensorNum];
float[][] sensorHist = new float[sensorNum][streamSize]; //history data to show
float[][] diffArray = new float[sensorNum][streamSize]; //diff calculation: substract
float[] modeArray = new float[streamSize]; //To show activated or not
float[][] thldArray = new float[sensorNum][streamSize]; //diff calculation: substract
int activationThld = 8; //The diff threshold of activiation

int windowSize = 25; //The size of data window
float[][] windowArray = new float[sensorNum][windowSize]; //data window collection
boolean b_sampling = false; //flag to keep data collection non-preemptive
int sampleCnt = 0; //counter of samples

// FEATURES
double[] windowSlope = new double[sensorNum];

Table csvData;
boolean b_saveCSV = false;
String dataSetName = "ArjoTrain"; 
String[] attrNames = new String[]{"slope_x", "slope_y", "slope_z", "label"};
boolean[] attrIsNominal = new boolean[]{false, false, false, true};
int labelIndex = 0;

// MODEL TRAINING
String modelName = "LinearSVC.model";
double[] CArray = {1, 2, 4, 8, 16, 32, 64, 128, 256};
double currentC = 4;
PGraphics pg_info;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];

Table[] tempCSV = new Table[sensorNum];
PGraphics[] pg2 = new PGraphics[sensorNum];

int label = 0;
LinearRegression lReg;
Instances training;
ArrayList<Attribute> attributes;

float[] sensorMin = new float[sensorNum];
float[] sensorMax = new float[sensorNum];


void setup() {
  size(1200, 600, P3D);
  
  initCSV();
  initLinearRegression();
  
  pg_info = createGraphics(width, height);
  monospace = createFont("SourceCodePro-Regular.ttf", 34);
  
  kinect = new Kinect(this);
  kinect.enableMirror(true);
  kinect.initDepth();
  kinect.initVideo();
  
  camera = new Camera();
  ortho();

  parameterSetup();
  productColors = new ProductColors();

  // Lookup table for all possible depth values (0 - 2047)
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
  
  demoSetup();
  
}


void draw() {
  colorImage = kinect.getVideoImage();
  if (canLoseTracking) {
    canLoseTracking = false;
    lostTracking = false;
  }
  
  background(0);
  
  
  
  if (action == "calibrate") {
    getKinectData();
    if (!productColors.pickColors) {
      parameterList.update();
    }
    productColors.render();
    drawCurrentAction();
    
  } else if (action == "collect_data") {
    getKinectData();
    newData();
    drawCollectionInfo();
    productColors.render();
    drawCurrentAction();
    
    if (b_saveCSV) {
      saveTable(csvData, "data/"+dataSetName+".csv");
      saveARFF(csvData, dataSetName);
      b_saveCSV = false;
    }
    
  } else if (action == "train_model") {
    if (actionChange) {
      
      // TRAIN MODEL
      loadTrainARFF(dataset=dataSetName+".arff");
      
      CSearchLinear(CArray);
      
      
      
      trainLinearSVC(C=currentC);
      setModelDrawing(unit=2);
      evaluateTrainSet(fold=5, isRegression=false, showEvalDetails=true);
      saveModel(model=modelName);
      
      actionChange = false;
    }
    pushStyle();
    
    pg_info.beginDraw();
    pg_info.background(0);
    pg_info.textFont(monospace);
    
    pg_info.textSize(20);
    pg_info.fill(255);
    pg_info.textAlign(RIGHT, TOP);
    pg_info.text("Currently trained model: "+modelName+"\n", width, 0);
    pg_info.text("From dataset: "+dataSetName+".arff\n", width, 40);
    pg_info.text("With C="+currentC+"\n", width, 80);
    pg_info.textSize(10);
    pg_info.textAlign(LEFT);
    try {
      String str = eval.toSummaryString("\nResults\n======\n", false);
      str += eval.toMatrixString();
      str += eval.toClassDetailsString();
      pg_info.text(str, 0, 0);
    } catch(java.lang.Exception e) {
      println(e);
    }
    pg_info.endDraw();
    popStyle();
    
    image(pg_info, 0,0);
    
    int size = 500;
    drawCSearchModels(width-size, height-size, size, size);
    drawCSearchResults(width-size, height-size, size, size);
    drawCurrentAction();
    
  } else if (action == "demo") {
    if (actionChange) {
      currentProductAmount = 0;
      currentState = 0;
      
      // LOAD MODEL
      
      
      actionChange = false;
    }
    
    getKinectData();
    newData();
    demoDraw();
    
  }
}
