class Path {
  ArrayList<PVector> positions;


  Path() {
    positions = new ArrayList<PVector>();
  }

  void add(PVector m) {
    positions.add(m);
  }

  void draw(MultiChannelBuffer b) {

    pushStyle();
    stroke(0);
    strokeWeight(1);
    noFill();
    beginShape();
    for (int i = 0; i < positions.size()-1; i++) {
      vertex(positions.get(i).x, positions.get(i).y);
      println(positions.get(i).dist(positions.get(i+1)));
    }

    endShape();
    popStyle();
  }
}
