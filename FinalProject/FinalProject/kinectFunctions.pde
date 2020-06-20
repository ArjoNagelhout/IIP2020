// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

PVector depthToWorld(int x, int y, int depthValue) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

  PVector result = new PVector();
  double depth =  depthLookUp[depthValue];//rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}

// https://graphics.stanford.edu/~mdfisher/Code/Engine/Matrix4.cpp.html
PVector WorldToColor(PVector worldPoint)//const Vec3f &pt)
{
    final double fx_rgb = 5.2921508098293293e+02;
    final double fy_rgb = 5.2556393630057437e+02;
    final double cx_rgb = 3.2894272028759258e+02;
    final double cy_rgb = 2.6748068171871557e+02;
    
    final double n00 = 9.9984628826577793e-01;
    final double n01 = -1.4779096108364480e-03;
    final double n02 = 1.7470421412464927e-02;
    final double n03 = -1.9792550277216193e-02;
    
    final double n10 = 1.2635359098409581e-03;
    final double n11 = 9.9992385683542895e-01;
    final double n12 = 1.2275341476520762e-02;
    final double n13 = 8.5293531401120742e-04;
    
    final double n20 = -1.7487233004436643e-02;
    final double n21 = -1.2251380107679535e-02;
    final double n22 = 9.9977202419716948e-01;
    final double n23 = 1.1254616236441769e-02;
    
    PVector transformedPos = new PVector();
    
    double x = worldPoint.x;
    double y = worldPoint.y;
    double z = worldPoint.z;
    
    
    transformedPos.x = (float)(n00*x + n01*y + n02*z + n03);
    transformedPos.y = (float)(n10*x + n11*y + n12*z + n13);
    transformedPos.z = (float)(n20*x + n21*y + n22*z + n23);
    
    
    //const float invZ = 1.0f / transformedPos.z;
    float invZ = 1.0 / transformedPos.z;

    PVector result = new PVector();
    //result.x = Utility::Bound(Math::Round((transformedPos.x * fx_rgb * invZ) + cx_rgb), 0, 639);
    //result.y = Utility::Bound(Math::Round((transformedPos.y * fy_rgb * invZ) + cy_rgb), 0, 479);
    result.x = round((float)((transformedPos.x * fx_rgb * invZ) + cx_rgb)); // No need for constrain()
    result.y = round((float)((transformedPos.y * fy_rgb * invZ) + cy_rgb));
    
    return result;
}
