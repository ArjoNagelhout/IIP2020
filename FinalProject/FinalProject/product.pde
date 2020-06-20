class Product {
  
  float targetX, targetY, targetZ;
  float currentX, currentY, currentZ;
  
  float mappedX, mappedY, mappedZ;
  
  int c;
  
  Product(int c) {
    this.c = c;
  }
  
  void renderDebug() {
    float l = floatParameter("lerpSpeed");
    currentX = lerp(currentX, targetX, l);
    currentY = lerp(currentY, targetY, l);
    currentZ = lerp(currentZ, targetZ, l);
    
    
    
    //PVector v = depthToWorld((int)currentX, (int)currentY, (int)currentZ);
    
    
    pushMatrix();
    // Scale up by 200
    translate(currentX*factor, currentY*factor, factor-currentZ*factor);
    if (debugInfo) {
      fill(c);
      noStroke();
      textSize(2);
      text("x="+currentX*factor+"\ny="+currentY*factor+"\nz="+currentZ*factor, 0, 0);
      sphere(floatParameter("productSize"));
    }
    mappedX = screenX(currentX, currentY, currentZ);
    mappedY = screenY(currentX, currentY, currentZ);
    mappedZ = screenZ(currentX, currentY, currentZ);
    popMatrix();
    textSize(14);
    
  }
}
