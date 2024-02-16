let vid;
let playing;
let img1, img2, img3;
let selection;
let space;
let startTime;
let Dresults = [];
let Redirectlink ="http://localhost:9000/jatos/33"; //später mit Redcap ersetzen

const slots = {
  slot1: "Slot1",
  slot2: "Slot2",
  slot3: "Slot3",
  slot4: "Slot4",
  slot5: "Slot5",
  slot6: "Slot6",
  slot7: "Slot7",
  slot8: "Slot8",
  slot9: "Slot9",
  slot10: "Slot10"
}


function setup() {
  createCanvas(displayWidth-200, displayHeight-200);
  background(127);

  textSize(32);
  fill(255);
  stroke(255);

  selection = 1;
  space = 0;
  
  /* vid = createVideo("test1.mp4");
  vid.loop()
  vid.speed(10);
  vid.pause(); */

  img1 = loadImage('assets/2sa.png');
  img2 = loadImage('assets/4.png');
  startTime= Date.now(); // Initial Starttime after images are loaded
}

function draw() {
  background(27);   //my windows space
  //line(width/2, 0, width/2, height);

  renderBackground();
  renderUI();

  //debug
  textSize(16);
  text('selection', 10, 30);
  text(selection, 80, 30);
}




function keyPressed() {
  if (keyCode == UP_ARROW) {
    selection++;
  }
  else if (keyCode == DOWN_ARROW) {
    selection--;
  }

  if (keyCode == RETURN ) {
    let responseTime = Date.now()- startTime; // Zeitunterschied messen
    Dresults.push({
      'stage': space+1,
      'option': selection+1,
      'Antwortzeit': responseTime
    });// aktuelle Daten in Dresults pushen
    if(space==1) {
      jatos.submitResultData(JSON.stringify(Dresults)).then(function() {
        jatos.endStudyAndRedirect(Redirectlink); // 
      });
    }
    else space++;  // Falls beim zweiten Task (also space=1) Studie beenden und redirect zu Redcap sonst gehe zum nächsten Task 
    selection = 2;
    startTime= Date.now(); //Start time von zweiten task

  }
  if (space == 2) space = 0;

  if (selection < 0) selection = 0;
  if (space == 0) if (selection > 1) selection = 1;
  if (space == 1) if (selection > 2) selection = 2;
}

function mousePressed() {
  if (playing) {
    vid.pause();
  }
   else {
     vid.play();
   }
   playing = !playing;
 }


function renderUI() {
  let uiX = width - 200;
  let uiY = height - 100;

  let offset = (selection + 1) * 40;

  textSize(32);
  if (space == 0) {
    text('Option 2', uiX - 50, uiY - 30);
    text('Option 1', uiX - 50, uiY - 70);
  }
  else {
    text('Option 5', uiX - 50, uiY - 30);
    text('Option 4', uiX - 50, uiY - 70);
    text('Option 3', uiX - 50, uiY - 110);
  }
  

  strokeWeight(3);
  line(uiX - 100, uiY - (offset - 20), uiX + 100, uiY - (offset - 20));
  line(uiX - 100, uiY - (offset + 20), uiX + 100, uiY - (offset + 20));
  strokeWeight(0);
}

function renderBackground() {
  if (space == 0)  image(img1, 0, 0, width, height);
  else image(img2, 0, 0, width, height);
}


function endStudy() {
 
}