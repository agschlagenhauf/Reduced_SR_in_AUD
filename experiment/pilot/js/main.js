/*
 * main.js
 */

/*
 * Study Session Data
 */
let participantID = null;
let variationID = null;
let environmentMap = {}; // mapping btw component & environment
let componentFlow = []; // list of component titles (reward learning etc.)
let componentIndex = 0; // current component index

/*
 * Component Flow
 */
function prepareComponentFlow(jatos) { // prepare list of what we should show
    participantID = 25; // get from JATOS

    componentFlow.push(StaticComponents.Intro); // add StaticComponents to componentFlow array

    const variation = Variations[participantID % Variations.length]; // get element of Variations based on participantID
    variationID = Object.keys(variation)[0]; // get e.g. A1, A2 etc. key
    const entries = variation[variationID]; // get content of variation element e.g. A1

    entries.forEach(function (entry, entryIndex) {
        const condition = Object.keys(entry)[0]; // get condition (key)
        const environment = entry[condition]; // get environment (value)

        Phases.forEach(function (phase) {
            const component = `${condition}-${phase}`; 
            environmentMap[component] = environment; // save environment to use per condition (easier to access later than going into Variations)
            componentFlow.push(component);
        });

        if (entryIndex < (entries.length - 1)) { // after every condition except last
            componentFlow.push(`interlude-${entryIndex + 1}`); // add interlude
        }
    });
    
    componentFlow.push(StaticComponents.Outro); // push outro

    jatos.studySessionData = { // save session data to pass to other components
        "participant_id": participantID,
        "variation_id": variationID,
        "environment_map": environmentMap,
        "component_flow": componentFlow,
        "component_index": componentIndex
    };
}

function startComponentFlow(jatos) { // start flow
    showNextComponent(jatos, null);
}

function showNextComponent(jatos, results) { // move through elements of componentFlow list
    componentIndex += 1;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, results); // tell JATOS to start new component & log results from current component
}

function loadStudySessionData(jatos) {
    participantID = jatos.studySessionData["participant_id"];
    variationID = jatos.studySessionData["variation_id"];
    environmentMap = jatos.studySessionData["environment_map"];
    componentFlow = jatos.studySessionData["component_flow"];
    componentIndex = jatos.studySessionData["component_index"];
}

function loadComponent(jatos, callback) { // load study session data abd wait fir JATOS
    jatos.onLoad(function() {
        loadStudySessionData(jatos);
        callback();
    });
}

function endComponentFlow(jatos) { // end flow (called in outro)

    // TODO: - Redirect to RedCap

    jatos.endStudy();
}

/*
 * State Configuration
 */

// input
// number = state number
// imageName = eg room1
// highlightTimeDelay = delay btw. cue onset & highlight in sec
// reward = in euro, null if nothing happens
// nextState = number of next state
class OneChoiceState {

    constructor(number, imageName, highlightTimeDelay, reward, nextState) {
        this.number = number;
        this.imageName = imageName;
        this.highlightTimeDelay = highlightTimeDelay;
        this.reward = reward;
        this.nextState = nextState;
    }
}

// input
// same as oneChoiceState 
// nextStateLeft = number of next state after left choice
// nextStateRight = number of next state after right choice
class TwoChoiceState {

    constructor(number, imageName, highlightTimeDelay, nextStateLeft, nextStateRight) {
        this.number = number;
        this.imageName = imageName;
        this.highlightTimeDelay = highlightTimeDelay;
        this.nextStateLeft = nextStateLeft;
        this.nextStateRight = nextStateRight;
    }
}

// within trial: function to draw screen for a state
// input
// stateNumber = state to be shown
// states = list of states defined in component
// trialResults = empty array to append results onto
// trialResultHandler = what to do after single trial finished
function configure(stateNumber, states, trialResults, trialResultHandler) {
    trialResults.push(stateNumber); // log current state number

    const state = states.find(function (state) { // find state number in list of states (according to number not position)
        return state.number == stateNumber;
    });
    
    setImageFromEnvironment(jatos, "image", state.imageName); // set image for current state

    doAfter(state.highlightTimeDelay, function() { // after delay defined per state, do...
        setImageFromEnvironment(jatos, "image", `${state.imageName}_highlighted`); // show same image with highlighted options

        if (state instanceof OneChoiceState) {
            enableOneChoiceInput(function() {

                // TODO: - Show reward

                if (state.reward) {
                    console.log(`Reward: ${state.reward}`);
                }

                doAfter(1.0, function() { // when last state per trial reached: handle results
                    if (state.nextState == null) {
                        trialResultHandler(trialResults);
                    }
                    else {
                        configure(state.nextState, states, trialResults, trialResultHandler); // as long as last state not reached yet: call configure again
                    }
                });
            });
        }
        else if (state instanceof TwoChoiceState) {
            enableTwoChoiceInput(function(input) {
                if (input == TwoChoiceInput.Left) {
                    //setImageFromEnvironment(jatos, "image", `${state.imageName}_left`);

                    //doAfter(1.0, function() {
                        configure(state.nextStateLeft, states, trialResults, trialResultHandler);
                    //});
                }
                else if (input == TwoChoiceInput.Right) {
                    //setImageFromEnvironment(jatos, "image", `${state.imageName}_right`);

                    //doAfter(1.0, function() {
                        configure(state.nextStateRight, states, trialResults, trialResultHandler);
                    //});
                }
            });
        }
    });
}

// function to run trials per component
// input
// initialStateNumbers = list of states from which to start per trial
// states = list of states defined in component
// aggregateResults = empty array to append results onto
// aggreagateResultHandler = what to do after all trials finished (usually showNextComponent)
function runTrials(initialStateNumbers, states, aggregateResults, aggregateResultHandler) { 

    configure(initialStateNumbers[0], states, [], function(trialResults) {
        aggregateResults.push(trialResults);
        initialStateNumbers.shift(); // remove first element

        if (initialStateNumbers.length > 0) { // if more trials to run, call runTrial again
            runTrials(initialStateNumbers, states, aggregateResults, aggregateResultHandler);
        }
        else {
            aggregateResultHandler(aggregateResults);
        }
    });
}

/*
 * User Input
 */
const Keyboard = { // allows to use Keyboard.F etc.
    F: "f",
    J: "j",
    LeftArrow: "ArrowLeft",
    RightArrow: "ArrowRight",
    Space: " "
};

const TwoChoiceInput = { // left and right choice, independent of which keys are used
    Left: "left",
    Right: "right"
};

function enableOneChoiceInput(callback) { // allowed keys for 1-choice states
    document.onkeydown = function(event) {
        if (event.key == Keyboard.Space) { // change input key here
            disableInput(); // disable any further input
            callback(); // call what I put in as callback function
        }
    };
}

function enableTwoChoiceInput(callback) { // allowed keys for 2-choice states
    document.onkeydown = function(event) {
        if (event.key == Keyboard.LeftArrow) { // change input key here
            disableInput(); // disable any further input
            callback(TwoChoiceInput.Left); // execute function defined as callback function with input TwoChoioceInput.Left
        }
        else if (event.key == Keyboard.RightArrow) { // change input key here
            disableInput(); // disable any further input
            callback(TwoChoiceInput.Right); // execute function defined as callback function with input TwoChoioceInput.Right
        }
    };
}

function disableInput() {
    document.onkeydown = null;
}

/*
 * Utilities
 */
function fadeOut(element, callback) {
    element.classList.add("fade_out");
    doAfter(0.5, callback);
}

function setImageFromEnvironment(jatos, id, imageName) { // set image to show based on environment mapping
    document.getElementById(id).src = `${getEnvironmentPath(jatos)}/${imageName}.png`;
}

function getEnvironmentPath(jatos) { // get path for component images
    const component = componentFlow[componentIndex];
    const environment = environmentMap[component]; // what color for current comnponent?
    const imagesPath = jatos.studyJsonInput["images_path"];

    return `${imagesPath}/${environment}`;
}

function doAfter(timeInterval, callback) { // execute function defined by callback after delay
    setTimeout(callback, timeInterval * 1000);
}

function shuffle(array) { // returns randomly shuffled elements
    let arrayCopy = [...array];
    let currentIndex = arrayCopy.length;

    while (currentIndex > 0) {
        let randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;

        // Swap elements
        [arrayCopy[currentIndex], arrayCopy[randomIndex]] = [arrayCopy[randomIndex], arrayCopy[currentIndex]];
    }

    return arrayCopy;
}

function pickRandom(array) {
    return array[Math.floor(Math.random() * array.length)];
}

/*
 * Static Components
 */
const StaticComponents = {
    Intro: "intro",
    Outro: "outro"
};

/*
 * Phases
 */
const Phases = [
    "learning",
    "relearning",
    "test"
];

/*
 * Learning Phase Start States
 */
const LearningPhaseStartStates = [1];

/*
 * Variations
 */
const Variations = [
    {
        "A1": [
            {"reward":      "light_blue"},
            {"transition":  "messy_green"},
            {"policy":      "orange_tile"},
            {"goal-state":  "red_brown"},
            {"control":     "white_modern"}
        ]
    },
    {
        "A2": [
            {"reward":      "messy_green"},
            {"transition":  "orange_tile"},
            {"policy":      "red_brown"},
            {"goal-state":  "white_modern"},
            {"control":     "light_blue"}
        ]
    },
    {
        "A3": [
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"},
            {"policy":      "white_modern"},
            {"goal-state":  "light_blue"},
            {"control":     "messy_green"}
        ]
    },
    {
        "A4": [
            {"reward":      "red_brown"},
            {"transition":  "white_modern"},
            {"policy":      "light_blue"},
            {"goal-state":  "messy_green"},
            {"control":     "orange_tile"}
        ]
    },
    {
        "A5": [
            {"reward":      "white_modern"},
            {"transition":  "light_blue"},
            {"policy":      "messy_green"},
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"}
        ]
    },
    {
        "B1": [
            {"transition":  "light_blue"},
            {"policy":      "messy_green"},
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"},
            {"reward":      "white_modern"}
        ]
    },
    {
        "B2": [
            {"transition":  "messy_green"},
            {"policy":      "orange_tile"},
            {"goal-state":  "red_brown"},
            {"control":     "white_modern"},
            {"reward":      "light_blue"}
        ]
    },
    {
        "B3": [
            {"transition":  "orange_tile"},
            {"policy":      "red_brown"},
            {"goal-state":  "white_modern"},
            {"control":     "light_blue"},
            {"reward":      "messy_green"}
        ]
    },
    {
        "B4": [
            {"transition":  "red_brown"},
            {"policy":      "white_modern"},
            {"goal-state":  "light_blue"},
            {"control":     "messy_green"},
            {"reward":      "orange_tile"}
        ]
    },
    {
        "B5": [
            {"transition":  "white_modern"},
            {"policy":      "light_blue"},
            {"goal-state":  "messy_green"},
            {"control":     "orange_tile"},
            {"reward":      "red_brown"}
        ]
    },
    {
        "C1": [
            {"policy":      "light_blue"},
            {"goal-state":  "messy_green"},
            {"control":     "orange_tile"},
            {"reward":      "red_brown"},
            {"transition":  "white_modern"}
        ]
    },
    {
        "C2": [
            {"policy":      "messy_green"},
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"},
            {"reward":      "white_modern"},
            {"transition":  "light_blue"}
        ]
    },
    {
        "C3": [
            {"policy":      "orange_tile"},
            {"goal-state":  "red_brown"},
            {"control":     "white_modern"},
            {"reward":      "light_blue"},
            {"transition":  "messy_green"}
        ]
    },
    {
        "C4": [
            {"policy":      "red_brown"},
            {"goal-state":  "white_modern"},
            {"control":     "light_blue"},
            {"reward":      "messy_green"},
            {"transition":  "orange_tile"}
        ]
    },
    {
        "C5": [
            {"policy":      "white_modern"},
            {"goal-state":  "light_blue"},
            {"control":     "messy_green"},
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"}
        ]
    },
    {
        "D1": [
            {"goal-state":  "light_blue"},
            {"control":     "messy_green"},
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"},
            {"policy":      "white_modern"}
        ]
    },
    {
        "D2": [
            {"goal-state":  "messy_green"},
            {"control":     "orange_tile"},
            {"reward":      "red_brown"},
            {"transition":  "white_modern"},
            {"policy":      "light_blue"}
        ]
    },
    {
        "D3": [
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"},
            {"reward":      "white_modern"},
            {"transition":  "light_blue"},
            {"policy":      "messy_green"}
        ]
    },
    {
        "D4": [
            {"goal-state":  "red_brown"},
            {"control":     "white_modern"},
            {"reward":      "light_blue"},
            {"transition":  "messy_green"},
            {"policy":      "orange_tile"}
        ]
    },
    {
        "D5": [
            {"goal-state":  "white_modern"},
            {"control":     "light_blue"},
            {"reward":      "messy_green"},
            {"transition":  "orange_tile"},
            {"policy":      "red_brown"}
        ]
    },
    {
        "E1": [
            {"control":     "light_blue"},
            {"reward":      "messy_green"},
            {"transition":  "orange_tile"},
            {"policy":      "red_brown"},
            {"goal-state":  "white_modern"}
        ]
    },
    {
        "E2": [
            {"control":     "messy_green"},
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"},
            {"policy":      "white_modern"},
            {"goal-state":  "light_blue"}
        ]
    },
    {
        "E3": [
            {"control":     "orange_tile"},
            {"reward":      "red_brown"},
            {"transition":  "white_modern"},
            {"policy":      "light_blue"},
            {"goal-state":  "messy_green"}
        ]
    },
    {
        "E4": [
            {"control":     "red_brown"},
            {"reward":      "white_modern"},
            {"transition":  "light_blue"},
            {"policy":      "messy_green"},
            {"goal-state":  "orange_tile"}
        ]
    },
    {
        "E5": [
            {"control":     "white_modern"},
            {"reward":      "light_blue"},
            {"transition":  "messy_green"},
            {"policy":      "orange_tile"},
            {"goal-state":  "red_brown"}
        ]
    }
];

// callback is a function that is passed into another function so that it can be executed after waiting for asynchronous event
