class ProductColors {
  
  ArrayList<ArrayList<Integer>> colors;
  boolean pickColors;
  int currentColor;
  int currentSample;
  int y;
  int displaySize = 50;
 
  ProductColors() {
    colors = new ArrayList<ArrayList<Integer>>();
    products = new ArrayList<Product>();
    y = height-displaySize;
  }
  
  void keyPressed_() {
    if (key == 'P' || key == 'p') {
      pickColors = !pickColors;
    }
    if (keyCode == DOWN) {
      if (currentSample > 0) {
        currentSample -= 1;
      }
    }
    if (keyCode == UP) {
      if (currentColor < colors.size()) {
        if (currentSample < colors.get(currentColor).size()) {
          currentSample += 1;
        }
      }
    }
    if (keyCode == LEFT) {
      if (currentColor > 0) {
        currentColor -= 1;
        currentSample = 0;
      }
    }
    if (keyCode == RIGHT) {
      if (currentColor < colors.size()) {
        currentColor += 1;
        currentSample = 0;
      }
    }
  }
  
  void mousePressed_() {
    
    color c = colorImage.get(mouseX, mouseY);
    
    if (currentColor >= colors.size()) {
      ArrayList samples = new ArrayList<Integer>();
      samples.add(c);
      colors.add(samples);
      products.add(new Product(c));
    } else {
      ArrayList samples = colors.get(currentColor);
      if (currentSample >= samples.size()) {
        samples.add(c);
      } else {
        samples.set(currentSample, c);
      }
      products.get(currentColor).c = c;
    }
    
    
    
  }
  
  void render() {
    
    /*if (parameterList.offScreen) {
      return;
    }*/
    
    int yy = y;
    int offset = 20;
    
    pushStyle();
    textSize(14);
    
    fill(255);
    text("currentColor = "+currentColor, width/2, yy-=offset);
    text("currentSample = "+currentSample, width/2, yy-=offset);
    text("pickColors = "+pickColors, width/2, yy-=offset);
    text("colors.size() = "+colors.size(), width/2, yy-=offset);
    
    for (int i = 0; i < colors.size(); i++) {
      ArrayList samples = colors.get(i);
      
      for (int s = 0; s < samples.size(); s++) {
        fill((int)samples.get(s));
        rect(width-i*displaySize-displaySize, y-s*displaySize, displaySize, displaySize);
        fill(255);
        text(i, width-i*displaySize-displaySize/2, y+displaySize/2);
      }
      
    }
    popStyle();
  }
  
}
