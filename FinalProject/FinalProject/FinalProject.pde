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

String action = "callibrate";
/*
"callibrate"
"collect_data"
"train_model"

*/

int sensorNum = 3; 
int streamSize = 500;
int[] rawData = new int[sensorNum];
float[][] sensorHist = new float[sensorNum][streamSize]; //history data to show

float[][] diffArray = new float[sensorNum][streamSize]; //diff calculation: substract

float[] modeArray = new float[streamSize]; //To show activated or not
float[][] thldArray = new float[sensorNum][streamSize]; //diff calculation: substract
int activationThld = 10; //The diff threshold of activiation

int windowSize = 20; //The size of data window
float[][] windowArray = new float[sensorNum][windowSize]; //data window collection
boolean b_sampling = false; //flag to keep data collection non-preemptive
int sampleCnt = 0; //counter of samples

//Statistical Features
float[] windowM = new float[sensorNum]; //mean
float[] windowSD = new float[sensorNum]; //standard deviation

Table csvData;
boolean b_saveCSV = false;
String dataSetName = "ArjoTrain"; 
String[] attrNames = new String[]{"m_x", "sd_x", "label"};
boolean[] attrIsNominal = new boolean[]{false, false, true};
int labelIndex = 0;



// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];


Table[] tempCSV = new Table[sensorNum];
String fileName = "data/testData.csv";
boolean b_savetempCSV = false;
boolean b_train = false;
boolean b_test = false;
PGraphics[] pg2 = new PGraphics[sensorNum];

int label = 0;
LinearRegression lReg;
Instances training;
ArrayList<Attribute> attributes;


void setup() {
  size(1200, 600, P3D);
  
  for (int c = 0; c < sensorNum; c++) {
    pg2[c] = createGraphics(width/sensorNum, height/3);
    pg2[c].beginDraw();
    pg2[c].background(200);
    pg2[c].endDraw();
    
    // Create a new table
    tempCSV[c] = new Table();
    tempCSV[c].addColumn("index");
    tempCSV[c].addColumn("value");
    
    saveCSV(tempCSV[c], "data/tempCSV_"+c+".csv");
    
    print(c);
  }
  
  
  
  //fullScreen(P3D);
  kinect = new Kinect(this);
  
  kinect.enableMirror(true);
  camera = new Camera();
  kinect.initDepth();
  kinect.initVideo();
  
  ortho();

  // Parameter setup
  ArrayList<Parameter> parameters = new ArrayList<Parameter>();
  int h = -10;
  int offset = 20;

  parameters.add(new IntParameter("minDepth", 0, 2048, 0, h+=offset));
  parameters.add(new IntParameter("maxDepth", 0, 2048, 716, h+=offset));
  parameters.add(new IntParameter("minW", 0, kinect.width, 0, h+=offset));
  parameters.add(new IntParameter("maxW", 0, kinect.width, kinect.width, h+=offset));
  parameters.add(new IntParameter("minH", 0, kinect.height, 0, h+=offset));
  parameters.add(new IntParameter("maxH", 0, kinect.height, kinect.height, h+=offset));
  parameters.add(new IntParameter("xOffset", -100, 100, -45, h+=offset));
  parameters.add(new IntParameter("yOffset", -100, 100, -18, h+=offset));
  parameters.add(new IntParameter("zOffset", -100, 100, -35, h+=offset));
  parameters.add(new FloatParameter("imageScale", 0.2, 2, 0.322, h+=offset));
  parameters.add(new IntParameter("skip", 1, 8, 2, h+=offset));
  parameters.add(new IntParameter("xColorOffset", -100, 100, 40, h+=offset));
  parameters.add(new IntParameter("yColorOffset", -100, 100, -14, h+=offset));
  parameters.add(new FloatParameter("maxColorDifference", 0, 300, 23, h+=offset));
  parameters.add(new IntParameter("minColors", 0, 100, 15, h+=offset));
  parameters.add(new FloatParameter("productSize", 1, 50, 3, h+=offset));
  parameters.add(new FloatParameter("lerpSpeed", 0.01, 1, 0.9, h+=offset));
  parameters.add(new IntParameter("dangerHeight", 10, 300, 100, h+=offset));
  parameters.add(new FloatParameter("panWidth", 10, 400, 267, h+=offset));
  parameters.add(new IntParameter("informationOffsetX", -400, 400, 282, h+=offset));
  parameters.add(new IntParameter("informationOffsetY", -400, 400, 248, h+=offset));
  parameters.add(new IntParameter("panHeight", 0, 500, 280, h+=offset)); 
  
  parameterList = new ParameterList(parameters, 400);
  productColors = new ProductColors();

  // Lookup table for all possible depth values (0 - 2047)
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
  
  initCSV();
  
}


void draw() {
  background(0);
  
  if (canLoseTracking) {
    canLoseTracking = false;
    lostTracking = false;
  }
  
  pushMatrix();
  colorImage = kinect.getVideoImage();
  
  if (productColors.pickColors) {
    image(colorImage, 0, 0);
  } else {
    // Get the raw depth as array of integers
    int[] depth = kinect.getRawDepth();

    // We're just going to calculate and draw every 4th pixel (equivalent of 160x120)
    int skip = intParameter("skip");

    camera.update();
    //rotateZ(radians(180));

    
    if (showImage) {
      pushMatrix();

      translate(0, 0, intParameter("zOffset"));
      scale(floatParameter("imageScale"));

      translate(-colorImage.width/2+intParameter("xOffset"), -colorImage.height/2+intParameter("yOffset"), 0);

      image(colorImage, 0, 0);
      popMatrix();
    }
    
    strokeWeight(0.5);
    
    float[] productX = new float[productColors.colors.size()];
    float[] productY = new float[productColors.colors.size()];
    float[] productZ = new float[productColors.colors.size()];
    float[] productAmount = new float[productColors.colors.size()];

    for (int x = 0; x < kinect.width; x += skip) {
      for (int y = 0; y < kinect.height; y += skip) {
        int offset = x + y*kinect.width;

        // Convert kinect data to world xyz coordinate
        int rawDepth = depth[offset];

        if (
          (rawDepth <= intParameter("maxDepth")) && 
          (rawDepth >= intParameter("minDepth")) && 
          (x > intParameter("minW")) &&
          (x < intParameter("maxW")) &&
          (y > intParameter("minH")) &&
          (y < intParameter("maxH"))
          ) {

          PVector v = depthToWorld(x, y, rawDepth);

          pushMatrix();
          float factor = 200;
          translate(v.x*factor, v.y*factor, factor-v.z*factor);

          PVector colorCoords = WorldToColor(v);
          color c = colorImage.get((int)colorCoords.x + intParameter("xColorOffset"), (int)colorCoords.y + intParameter("yColorOffset"));
          
          int colorIndex = getProduct(c);
          if (colorIndex != -1) {
            c = productColors.colors.get(colorIndex).get(0);
            productX[colorIndex] += v.x;
            productY[colorIndex] += v.y;
            productZ[colorIndex] += v.z;
            productAmount[colorIndex] += 1;
          }
          if (coloredPixels) {
            stroke(c);
          } else {
            stroke(255);
          }

          if (renderPixels) {
            point(0, 0);
          }
          popMatrix();
        }
      }
    }
    for (int i = 0; i < products.size(); i++) {
      Product p = products.get(i);
      
      if (productAmount[i] > intParameter("minColors")) {
        p.targetX = productX[i]/productAmount[i];
        p.targetY = productY[i]/productAmount[i];
        p.targetZ = productZ[i]/productAmount[i];
        canLoseTracking = true;
      
      } else {
        lostTracking = true;
      }
      p.renderDebug();
      
        
    }
  }
  strokeWeight(1);

  popMatrix();

  //translate(0, 0, 200);
  
  if (!productColors.pickColors) {
    parameterList.update();
  }
  
  pushStyle();
  fill(255);
  textSize(30);
  text(action, width/2, height/2);
  popStyle();
  
  if (action == "collect_data" || action == "train_model") {
    newData();
    
    lineGraph(sensorHist[0], 0, 500, 0, 0, width, height/3, 0); //draw sensor stream
    lineGraph(diffArray[0], 0, 500, 0, height/3, width, height/3, 1); //history of signal
    lineGraph(thldArray[0], 0, 500, 0, height/3, width, height/3, 2); //history of signal
    barGraph (modeArray, 0, height/3, width, height/3);
    showInfo("Thld: "+activationThld, 20, 2*height/3-20);
    showInfo("([A]:+/[Z]:-)", 20, 2*height/3);
    lineGraph(windowArray[0], 0, 1023, 0, 2*height/3, width, height/3, 3); //history of window
    showInfo("M: "+nf(windowM[0], 0, 2), 20, 2*height/3-60);
    showInfo("SD: "+nf(windowSD[0], 0, 2), 20, 2*height/3-40);
    showInfo("Current Label: "+getCharFromInteger(labelIndex), 20, 20);
    showInfo("Num of Data: "+csvData.getRowCount(), 20, 40);
    showInfo("[X]:del/[C]:clear/[S]:save", 20, 60);
    showInfo("[/]:label+", 20, 80);
    
    
    // Draw the linear regressions
    for (int c = 0; c < sensorNum; c++) { 
      if (pg2[c] != null) {
        image(pg2[c], c*(width/3), height-(height/3));
      }
      pushMatrix();
      translate(c*(width/3), height-(height/3));
      
      pushStyle();
      stroke(255, 0, 0);
      strokeWeight(5);
      
      int _sampleCount = tempCSV[c].getRowCount();
      if (_sampleCount > 0) {
        int xMultiplier = (width/3)/_sampleCount;
        
        for (int i = 0; i < _sampleCount; i++) { 
          TableRow tableRow = tempCSV[c].getRow(i);
          
          point(tableRow.getInt("index") * xMultiplier, tableRow.getFloat("value"));
        }
      }
      
      popMatrix();
      popStyle();
    }
  }
  if (b_saveCSV) {
    saveCSV(dataSetName, csvData);
    saveARFF(dataSetName, csvData);
    b_saveCSV = false;
  }
  
  

  productColors.render();
  
}


void newData() {   
  
  float diff = 0;
  
  Product p = products.get(0);
  
  rawData[0] = int(p.currentX*factor);
  appendArray( (sensorHist[0]), rawData[0]); //store the data to history (for visualization)
  diff = max(abs( (sensorHist[0])[0] - (sensorHist[0])[1]), diff); //absolute diff
  appendArray(diffArray[0], diff);
  appendArray(thldArray[0], activationThld);
  
  rawData[1] = int(p.currentY*factor);
  appendArray( (sensorHist[1]), rawData[1]); //store the data to history (for visualization)
  diff = max(abs( (sensorHist[1])[0] - (sensorHist[1])[1]), diff); //absolute diff
  appendArray(diffArray[1], diff);
  appendArray(thldArray[1], activationThld);
  
  rawData[2] = int(p.currentZ*factor);
  appendArray( (sensorHist[2]), rawData[2]); //store the data to history (for visualization)
  diff = max(abs( (sensorHist[2])[0] - (sensorHist[2])[1]), diff); //absolute diff
  appendArray(diffArray[2], diff);
  appendArray(thldArray[2], activationThld);
  
  //test activation threshold
  if ((lostTracking == false) && (diff>activationThld)) {
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
    if (b_sampling == true) {
      appendArray(modeArray, 3);
    } else {
      appendArray(modeArray, -1); 
    }
  }

  if (b_sampling == true) {
    for ( int c = 0; c < sensorNum; c++) {
      appendArray(windowArray[c], rawData[c]); //store the windowed data to history (for visualization)
    }
    ++sampleCnt;
    if (sampleCnt == windowSize) {
      
      
      // COLLECT FEATURES
      for (int c = 0; c < sensorNum; c++) {
        
        // Perform linear regression for each time series data 
        
        tempCSV[c].clearRows();
        
        // Populate the table
        for (int i = 0; i < sampleCnt; i++) {
          TableRow newRow = tempCSV[c].addRow();
          newRow.setInt("index", i);
          newRow.setFloat("value", windowArray[c][i]);
          
        }
        
        saveCSV(tempCSV[c], "data/tempCSV_"+c+".csv");
        
        try {
          initTrainingSet(tempCSV[c], 2); // in Weka.pde
          lReg = new LinearRegression();
          lReg.buildClassifier(training);
          modelEvaluation(c);
        }
        catch (Exception e) {
          e.printStackTrace();
        }
      }
      
      windowM[0] = Descriptive.mean(windowArray[0]); //mean
      windowSD[0] = Descriptive.std(windowArray[0], true); //standard deviation
      TableRow newRow = csvData.addRow();
      newRow.setFloat("m_x", windowM[0]);
      newRow.setFloat("sd_x", windowSD[0]);
      newRow.setString("label", getCharFromInteger(labelIndex));
      println(csvData.getRowCount());
      b_sampling = false; //stop sampling if the counter is equal to the window size
    }
  }
  return;
}


// Functions that pass through to the custom camera class
void mousePressed() {

  if (productColors.pickColors) {
    productColors.mousePressed_();
    return;
  }

  if (!parameterList.offScreen) {
    for (Parameter parameter : parameterList.parameters) {
      if (parameter.select()) {
        return;
      }
    }
  }

  

  camera.mousePressed_();
}

void mouseReleased() {

  if (productColors.pickColors) {

    return;
  }
  
  for (Parameter parameter : parameterList.parameters) {
    if (parameter.selected) {
      parameter.selected = false;
      return;
    }
  }
  

  camera.mouseReleased_();
}

void mouseWheel(MouseEvent event) {
  camera.mouseWheel_(event);
}

void keyPressed() {
  camera.keyPressed_();
  productColors.keyPressed_();
  if (key == 'G' || key == 'g') {
    parameterList.offScreen = !parameterList.offScreen;
  }
  if (key == 'I' || key == 'i') {
    showImage = !showImage;
  }
  if (key == 'O' || key == 'o') {
    coloredPixels = !coloredPixels;
  }
  if (key == 'R' || key == 'r') {
    renderPixels = !renderPixels;
  }
  if (key == '1') {
    // Collect data
    action = "callibrate";

  }
  if (key == '2') {
    // Train model
    if (products.size() > 0) {
      action = "collect_data";
    } else {
      print("You need to select a color\n");
    }
  }
  if (key == '3') {
    action = "train_model";
    // 
  }
  if (key == 'D' || key == 'd') {
    debugInfo = !debugInfo;
  }
  
  if (key == 'A' || key == 'a') {
    activationThld = min(activationThld+5, 100);
  }
  if (key == 'Z' || key == 'z') {
    activationThld = max(activationThld-5, 10);
  }
  if (key == 'C' || key == 'c') {
    csvData.clearRows();
    println(csvData.getRowCount());
  }
  if (key == 'X' || key == 'x') {
    csvData.removeRow(csvData.getRowCount()-1);
  }
  if (key == 'S' || key == 's') {
    b_saveCSV = true;
  }
  if (key == '/') {
    ++labelIndex;
    labelIndex %= 10;
  }
  if (key == '0') {
    labelIndex = 0;
  }
}

int intParameter(String name) {
  return ((IntParameter)getParameter(name)).currentValue;
}

float floatParameter(String name) {
  return ((FloatParameter)getParameter(name)).currentValue;
}

Parameter getParameter(String name) {
  return parameterList.parameters.get(parameterList.indexes.get(name));
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
