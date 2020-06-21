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
