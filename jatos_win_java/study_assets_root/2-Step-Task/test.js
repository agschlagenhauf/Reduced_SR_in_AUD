let y = 35;
function setup() {
  createCanvas(100, 100);
  stroke(0);
}

function draw() {
  background(204);
  line(10, 50, 90, 50);
  if (keyCode == UP_ARROW) {
    y = 20;
  }
  else if (keyCode == DOWN_ARROW) {
    y = 50;
  }
  else {
    y = 35;
  }
  rect(25, y, 50, 30);
}