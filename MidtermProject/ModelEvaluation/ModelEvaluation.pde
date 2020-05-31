//*********************************************

// Group 12
//Jesper Kapteijns
//Jeanine de Leeuw
//Arjo Nagelhout
//Danvy Vũ

// Course Interactive Intelligent Products
// Professor: Rong-Hao Liang: r.liang@tue.nl
//*********************************************

void setup() {
  size(500, 500, P2D);
  loadTrainARFF(dataset="DataSetTrain_v3.arff");//load a ARFF dataset
  loadTestARFF(dataset="DataSetTest_v3.arff");//load a ARFF dataset
  loadModel(model="LinearSVC.model"); //load a pretrained model.
  evaluateTestSet(isRegression = false, showEvalDetails=true);  //5-fold cross validation
}

void draw() {
  background(255);
}
