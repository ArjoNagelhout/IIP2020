void parameterSetup() {
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
}

class ParameterList {
  
  float animationSpeed = 0.3;
  
  float currentX, minX, maxX;
  boolean offScreen;
  
  ArrayList<Parameter> parameters;
  
  HashMap<String, Integer> indexes;
  
  ParameterList(ArrayList<Parameter> parameters, int w) {
    this.parameters = parameters;
    
    indexes = new HashMap<String, Integer>();
    
    for (int i = 0; i < parameters.size(); i++) {
      Parameter parameter = parameters.get(i);
      parameter.w = w;
      indexes.put(parameter.name, i);
    }
    
    minX = -w - 100;
    maxX = 0;
  }
  
  void update() {
    
    float targetX;
    if (offScreen) {
      targetX = minX;
    } else {
      targetX = maxX;
    }
    
    currentX = lerp(currentX, targetX, animationSpeed);
    
    pushMatrix();
    translate(currentX, 0);
    
    if (!(targetX-currentX<0.1 && offScreen == true)) {
      for (Parameter parameter : parameters) {
        parameter.update();
      }
    }
    popMatrix();
  }
  
}

class Parameter {

  float currentValue;

  String name;
  String displayString;

  float x = 10;
  float y;

  float w;
  float h = 10;

  float slider_x;
  float slider_w = 20;
  float slider_h = 15;

  boolean selected;

  void update() {



    pushMatrix();

    translate(x, y);
    stroke(0);
    fill(200);
    rect(0, 0, w, h, 5);

    if (selected) {
      fill(220);
    } else {
      fill(255);
    }

    rect(slider_x, h/2-slider_h/2, slider_w, slider_h, 5);

    fill(255);
    if (!parameterList.offScreen) {
      text(displayString, w, 0);
    }

    popMatrix();
  }

  boolean select() {
    if ((mouseX >= x) && (mouseX <= x + w) && (mouseY >= y+(h/2-slider_h/2)) && (mouseY <= y+(h/2+slider_h/2))) {
      selected = true;
      return true;
    } else {
      return false;
    }
  }
}

class IntParameter extends Parameter {

  int currentValue, minValue, maxValue;

  IntParameter(String name, int minValue, int maxValue, int currentValue, int y) {
    this.name = name;
    
    this.currentValue = currentValue;
    this.minValue = minValue;
    this.maxValue = maxValue;
    
    this.y = y;
  }

  void update() {
    //currentValue = maxValue/2 + (int)(sin((float)millis()/50)*((float)(maxValue-minValue)/2));

    if (selected) {
      
      currentValue = minValue + int(((mouseX - x - slider_w/2) / (w-slider_w)) * (float)(maxValue-minValue));
      
    }
    
    currentValue = constrain(currentValue, minValue, maxValue);

    slider_x = (w - (slider_w)) * (((float)(currentValue-minValue)/((float)(maxValue-minValue))));
    
    displayString = "Int " + name + " = " + currentValue;

    super.update();
  }
}

class FloatParameter extends Parameter {

  float currentValue, minValue, maxValue;

  FloatParameter(String name, float minValue, float maxValue, float currentValue, int y) {
    this.name = name;
    
    this.currentValue = currentValue;
    this.minValue = minValue;
    this.maxValue = maxValue;
    
    this.y = y;
  }

  void update() {
    
    if (selected) {
      currentValue = ((mouseX - x - slider_w/2) / (w-slider_w)) * (float)(maxValue-minValue);
    }
    
    currentValue = constrain(currentValue, minValue, maxValue);

    slider_x = (w - (slider_w)) * (currentValue/(maxValue-minValue));
    
    displayString = "Float " + name + " = " + currentValue;

    super.update();
  }
}
