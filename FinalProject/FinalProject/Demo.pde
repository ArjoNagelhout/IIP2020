PImage screenScan;
PImage screenDelete;
PImage screenPay;
PImage screenLongReceipt;
PImage screenShortReceipt;
PImage product;
PImage selectedProduct;

int currentState = 0; 
int currentProductAmount = 0;
int maxProductAmount = 3;
int currentlySelectedProduct = 0;
int productX = 663;
int productY = 244;
int productHeight = 189;

int currentPrediction = 0; // 0 is left, 1 is right and 2 is select
boolean newIncomingPrediction = false;
boolean firstTime = true;

/*
0: scan
1: delete
2: pay
3: long receipt
4: short receipt

663, 244 locatie product
189 hoogte product
*/

void demoSetup() {
  screenScan = loadImage("zelfscanplein-01.png");
  screenDelete = loadImage("zelfscanplein-02.png");
  screenPay = loadImage("zelfscanplein-03.png");
  screenLongReceipt = loadImage("zelfscanplein-04.png");
  screenShortReceipt = loadImage("zelfscanplein-05.png");
  product = loadImage("zelfscanplein-06.png");
  selectedProduct = loadImage("zelfscanplein-07.png");
}

void demoDraw() {
  if (newIncomingPrediction) {
    
    
    // Do all the logic here
    if (currentState == 0) {
      // SCAN SCREEN
      if (currentPrediction == 0) {
        // LEFT, delete product
        if (currentProductAmount > 0) {
          currentState = 1;
        }
      } else if (currentPrediction == 2) {
        // SELECT, checkout
        currentState = 2;
      }
    } else if (currentState == 1) {
      // DELETE SCREEN
      if (currentPrediction == 0) {
        // PREVIOUS
        if (currentlySelectedProduct > 0) {
          currentlySelectedProduct -= 1;
        }
      } else if (currentPrediction == 1) {
        // NEXT
        if (currentlySelectedProduct < currentProductAmount-1) {
          currentlySelectedProduct += 1;
        }
      } else if (currentPrediction == 2) {
        // ACTUALLY DELETE
        currentProductAmount -= 1;
        currentState = 0;
      }
    } else if (currentState == 2) {
      // PAY
      if (currentPrediction == 0) {
        // LEFT, korte bon
        currentState = 4;
      } else if (currentPrediction == 1) {
        currentState = 3;
      }
    }
    
    
    newIncomingPrediction = false;
  }

  if (currentState == 0) {
    image(screenScan, 0, 0);
  } else if (currentState == 1) {
    image(screenDelete, 0, 0);
  } else if (currentState == 2) {
    image(screenPay, 0, 0);
  } else if (currentState == 3) {
    image(screenLongReceipt, 0, 0);
  } else if (currentState == 4) {
    image(screenShortReceipt, 0, 0);
  }
  
  if (currentState != 4) {
    for (int i=0; i<currentProductAmount; i++) {
      if ((currentlySelectedProduct == i) && (currentState == 1)) {
        
        image(selectedProduct, productX, productY+productHeight*i);
      } else {
        image(product, productX, productY+productHeight*i);
      }
    }
  }
  


  
  //showInfo("Pred: "+Y,20,20);
  pushStyle();
  fill(0);
  textSize(120);
  textAlign(CENTER, CENTER);
  String display = "";
  if (currentPrediction == 0) {
    display = "<--";
  } else if (currentPrediction == 1) {
    display = "-->";
  } else if (currentPrediction == 2) {
    display = "SELECT";
  }
  text(display, width/5, height/2);
  popStyle();
}
