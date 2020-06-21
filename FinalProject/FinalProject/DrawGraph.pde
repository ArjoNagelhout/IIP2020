void drawCurrentAction() {
  pushStyle();
  fill(255);
  textSize(30);
  text(action, width/2, height/2);
  popStyle();
}


// Draw info
void drawCollectionInfo() {
  lineGraph(sensorHist[0], 0, 500, 0, 0, width, height/3, 0); //draw sensor stream
  lineGraph(diffArray[0], 0, 500, 0, height/3, width, height/3, 1); //history of signal
  lineGraph(thldArray[0], 0, 500, 0, height/3, width, height/3, 2); //history of signal
  barGraph (modeArray, 0, height/3, width, height/3);
  showInfo("Thld: "+activationThld, 20, 2*height/3-20);
  showInfo("([A]:+/[Z]:-)", 20, 2*height/3);
  lineGraph(windowArray[0], 0, 1023, 0, 2*height/3, width, height/3, 3); //history of window
  showInfo("slope_x: "+windowSlope[0], 20, 2*height/3-80);
  showInfo("slope_y: "+windowSlope[1], 20, 2*height/3-60);
  showInfo("slope_z: "+windowSlope[2], 20, 2*height/3-40);
  
  showInfo("Current Label: "+getCharFromInteger(labelIndex), 20, 20);
  showInfo("Num of Data: "+csvData.getRowCount(), 20, 40);
  showInfo("[X]:del/[C]:clear/[S]:save", 20, 60);
  showInfo("[/]:label+", 20, 80);
  
  
  // Draw the linear regressions
  for (int c = 0; c < sensorNum; c++) { 
    if (pg2[c] != null) {
      image(pg2[c], c*(width/sensorNum), height-(height/3));
    }
    pushMatrix();
    translate(c*(width/sensorNum), height-(height/3));
    
    pushStyle();
    stroke(255, 0, 0);
    strokeWeight(5);
    
    int _sampleCount = tempCSV[c].getRowCount();
    if (_sampleCount > 0) {
      int xMultiplier = (width/sensorNum)/_sampleCount;
      
      for (int i = 0; i < _sampleCount; i++) { 
        TableRow tableRow = tempCSV[c].getRow(i);
        
        point(tableRow.getInt("index") * xMultiplier, map(tableRow.getFloat("value"), sensorMin[c], sensorMax[c], 0, height/3));
      }
    }
    
    popMatrix();
    popStyle();
  }
}

//Draw text info
//showInfo(String s, int v, float x, float y)
void showInfo(String s, float x, float y) { 
  pushStyle();
  textAlign(LEFT,TOP);
  fill(255);
  textSize(20);
  text(s, x, y);
  popStyle();
}

//Draw a bar graph to visualize the modeArray
//barGraph(float[] data, float x, float y, float width, float height)
void barGraph(float[] data, float _x, float _y, float _w, float _h) {
  color colors[] = {
    color(255, 0, 0), color(0), color(0, 0, 255), color(255, 0, 255), 
    color(255, 0, 255)
  };
  pushStyle();
  noStroke();
  float delta = _w / data.length;
  for (int p = 0; p < data.length; p++) {
    float i = data[p];
    int cIndex = min((int) i, colors.length-1);
    if (i<0) fill(255, 100);
    else fill(colors[cIndex], 100);
    float h = map(0, -1, 0, 0, _h);
    rect(_x, _y-h, delta, h);
    _x = _x + delta;
  }
  popStyle();
}


//Draw a line graph to visualize the sensor stream
//lineGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height, int _index)  
void lineGraph(float[] data, float _l, float _u, float _x, float _y, float _w, float _h, int _index) {
  color colors[] = {
    color(255, 0, 0), color(0), color(0, 0, 255), color(255, 0, 255), 
    color(255, 0, 255)
  };
  int index = min(max(_index, 0), colors.length);
  pushStyle();
  float delta = _w/(data.length-1);
  beginShape();
  noFill();
  stroke(colors[index]);
  for (float i : data) {
    float h = map(i, _l, _u, 0, _h);
    vertex(_x, _y+h);
    _x = _x + delta;
  }
  endShape();
  popStyle();
}
