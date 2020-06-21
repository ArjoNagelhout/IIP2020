void getKinectData() {
  pushMatrix();
  if (productColors.pickColors) {
    image(colorImage, 0, 0);
  } else {
    
    // Get the raw depth as array of integers
    int[] depth = kinect.getRawDepth();
  
    // We're just going to calculate and draw every 4th pixel (equivalent of 160x120)
    int skip = intParameter("skip");
  
    camera.update();
    //rotateZ(radians(180));
    
    if (showImage && action != "demo") {
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
  
          if (renderPixels && action != "demo") {
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
      if (action != "demo") {
        p.renderDebug();
      }
      
        
    }
  }
  popMatrix();
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
        
        sensorMin[c] = 1000;
        sensorMax[c] = -1000;
        
        
        // Populate the table
        for (int i = 0; i < sampleCnt; i++) {
          TableRow newRow = tempCSV[c].addRow();
          newRow.setInt("index", i);
          float newValue = windowArray[c][i];
          newRow.setFloat("value", newValue);
          sensorMin[c] = min(sensorMin[c], newValue);
          sensorMax[c] = max(sensorMax[c], newValue);
          
        }
        
        saveCSV(tempCSV[c], "data/tempCSV_"+c+".csv");
        
        try {
          initTrainingSet(tempCSV[c], 2); // in Weka.pde
          lReg = new LinearRegression();
          lReg.buildClassifier(training);
          modelEvaluation(c);
          windowSlope[c] = lReg.coefficients()[0];
        }
        catch (Exception e) {
          e.printStackTrace();
        }
      }
      
      if (action == "demo") {
        // GET PREDICTION
        
        
        
      } else {
        
        // STORE IN CSV
        //windowM[0] = Descriptive.mean(windowArray[0]); //mean
        //windowSD[0] = Descriptive.std(windowArray[0], true); //standard deviation
        TableRow newRow = csvData.addRow();
        newRow.setFloat("slope_x", (float)windowSlope[0]);
        newRow.setFloat("slope_y", (float)windowSlope[1]);
        newRow.setFloat("slope_z", (float)windowSlope[2]);
        newRow.setString("label", getCharFromInteger(labelIndex));
        println(csvData.getRowCount());
        //saveTable(csvData, "data/test.csv");
        b_sampling = false; //stop sampling if the counter is equal to the window size
      }
    }
  }
  return;
}
