int getProduct(color c) {
  
  for (int i = 0; i < productColors.colors.size(); i++) {
    ArrayList samples = productColors.colors.get(i);
    for (int s = 0; s < samples.size(); s++) {
      float difference = getColorDifference(c, productColors.colors.get(i).get(s));
      if (difference < floatParameter("maxColorDifference")) {
        
        return i;
      }
    }
  }
  return -1;
  
}

float getColorDifference(color c1, color c2) {

  float difference = abs(red(c2)-red(c1)) + abs(green(c2)-green(c1)) + abs(blue(c2)-blue(c1));
  //println(difference);

  return difference;
}
