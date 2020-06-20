// Arjo Nagelhout - 18 oct 2019
// TUe Bachelor Industrial Design year 1 - Q1 From Idea to Design
// 

// Adapted from:
// Daniel Shiffman
// Kinect Point Cloud example

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

import org.openkinect.freenect.*;
import org.openkinect.processing.*;


// Kinect Library object
Kinect kinect;
Camera camera;

ParameterList parameterList;
ProductColors productColors;

ArrayList<Product> products;

boolean showImage = true;
boolean coloredPixels = true;
boolean renderPixels = true;
boolean debugInfo = true;
boolean showTopScreen = true;
boolean showBottomScreen = true;
PImage colorImage;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];


void setup() {
  size(1200, 600, P3D);
  
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
  parameters.add(new IntParameter("maxDepth", 0, 2048, 835, h+=offset));
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
  parameters.add(new IntParameter("minColors", 0, 100, 13, h+=offset));
  parameters.add(new FloatParameter("productSize", 1, 50, 3, h+=offset));
  parameters.add(new FloatParameter("lerpSpeed", 0.01, 1, 0.22, h+=offset));
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
  
}


void draw() {
  background(0);
  
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

  productColors.render();
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
  if (key == 'C' || key == 'c') {
    coloredPixels = !coloredPixels;
  }
  if (key == 'R' || key == 'r') {
    renderPixels = !renderPixels;
  }
  if (key == '1') {
    showTopScreen = !showTopScreen;
  }
  if (key == '2') {
    showBottomScreen = !showBottomScreen;
  }
  if (key == 'D' || key == 'd') {
    debugInfo = !debugInfo;
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
