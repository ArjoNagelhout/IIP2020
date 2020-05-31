//*********************************************

// Group 12
//Jesper Kapteijns
//Jeanine de Leeuw
//Arjo Nagelhout
//Danvy Vũ

// Course Interactive Intelligent Products
// Professor: Rong-Hao Liang: r.liang@tue.nl
//*********************************************

double[] CArray = {1, 2, 4, 8, 16, 32, 64, 128, 256};
boolean showModelOnly = false;

void setup() {
  size(500, 500, P2D);
  loadTrainARFF(dataset="DataSetTest_v3.arff");//load a ARFF dataset
  CSearchLinear(CArray);
}

void draw() {
  drawCSearchModels(0, 0, width, height);
  if (!showModelOnly) drawCSearchResults(0, 0, width, height);
}

void keyPressed() {
  if (key == ENTER || key == ENTER) {
    showModelOnly = (showModelOnly? false : true);
  }
}
