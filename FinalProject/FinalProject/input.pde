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
  
  if (key == ' ') {
    // Add product
    if (currentProductAmount < maxProductAmount) {
      currentProductAmount += 1;
    }
  }
  
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
    action = "calibrate";
    actionChange = true;
  }
  if (key == '2') {
    // Train model
    if (products.size() > 0) {
      action = "collect_data";
      actionChange = true;
    } else {
      print("You need to select a color\n");
    }
  }
  if (key == '3') {
    action = "train_model";
    actionChange = true;
    // 
  }
  if (key == '4') {
    if (products.size() > 0) {
      action = "demo";
      actionChange = true;
    } else {
      print("You need to select a color\n");
    }
  }
  if (key == '5') {
    actionChange = true;
    action = "evaluation";
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
