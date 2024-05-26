/*
 * main.js
 */




/*
 * Timing variables
 */

const preChoiceTime = 0.5; // time in state without highlighted choice options
const maxOneChoiceTime = 2.0; // max time in one choice state with highlighted choice option - ended as soon as valid key pressed
const maxTwoChoiceTime = 3.0; // max time in two choice state with highlighted choice option - ended as soon as valid key pressed
const maxTestChoiceTime = 10.0; // max time with highlighted options in test phase
const afterChoiceTimeNoReward = 2.0; // time after valid choice with no reward
const afterChoiceTimeReward = 2.5; // time after valid choice with reward presentation
const fadeoutTime = 0.5; // fadeout duration after each trial (and intro/outro component)
const ITI = 0.5; // inter trial interval



/*
 * Study Session Data
 */

// globally available
let participantID = null; // participant ID generated in RedCap
let runningID = null; // running ID generated in RedCap
let backCode = null; // code leading back to individual RedCap questionnaires when appended to RedCap backLink
let variationID = null; // which condition order and matching of condition and environment (see 'variations' at bottom of main.js)
let environmentMap = {
    "tutorial": "white_modern"
}; // mapping btw component & environment; environment of tutorial is always the same
let componentFlow = []; // list of component titles (reward learning etc.)
let componentIndex = 0; // current component index
let componentOnset = null; // onset time for each component



/*
 * Component Flow
 */

function prepareComponentFlow() { // prepare list of what we should show

    // read out link components
    //example link: http://127.0.0.1:9000/publix/xJoZc2UPD10?participant=30620126hqIHzHP2GhTvxYt
    //let urlQuery = jatos.urlQueryParameters.participant;
    let urlQuery = '30620126hqIHzHP2GhTvxYt';
    participantID = Number(urlQuery.substr(0,4)); 
    runningID = Number(urlQuery.substr(4,3));
    console.log(runningID);
    backCode = urlQuery.substr(7,urlQuery.length-7);
    //participantID = 25; // get from JATOS

    componentFlow.push( // add StaticComponents to componentFlow array
        StaticComponents.Intro1, 
        StaticComponents.Tutorial, 
        StaticComponents.Intro2, 
        StaticComponents.Quiz, 
        StaticComponents.QuizWrong, 
        StaticComponents.Intro3
    ); 

    const variation = Variations[runningID % Variations.length]; // get element of Variations based on participantID
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
        "running_id": runningID,
        "back_code": backCode,
        "variation_id": variationID,
        "environment_map": environmentMap,
        "component_flow": componentFlow,
        "component_index": componentIndex,
    };

    const correctFirstStateActionLearning = shuffle(["left", "left", "right", "right"]);; // which state 1 action is correct after learning

    jatos.studySessionData["control"] = { // save session data to pass to other components
        "correct_first_state_action_learning": correctFirstStateActionLearning[0]
    };
    jatos.studySessionData["reward"] = {
        "correct_first_state_action_learning": correctFirstStateActionLearning[1]
    };
    jatos.studySessionData["goal-state"] = {
        "correct_first_state_action_learning": correctFirstStateActionLearning[2]
    };
    jatos.studySessionData["transition"] = {
        "correct_first_state_action_learning": correctFirstStateActionLearning[3]
    };
    //jatos.studySessionData["policy"] = {
    //    "correct_first_state_action_learning": correctFirstStateActionLearning[4]
    //};

    preloadImages();

    componentOnset = performance.now();
}

//function startComponentFlow(componentData) { // start flow
//    showNextComponent(componentData); 
//}

function loadStudySessionData() {
    participantID = jatos.studySessionData["participant_id"];
    runningID = jatos.studySessionData["running_id"];
    backCode = jatos.studySessionData["back_code"];
    variationID = jatos.studySessionData["variation_id"];
    environmentMap = jatos.studySessionData["environment_map"];
    componentFlow = jatos.studySessionData["component_flow"];
    componentIndex = jatos.studySessionData["component_index"];
}

function loadComponent(callback) { // load study session data and wait for JATOS
    jatos.onLoad(function() {
        componentOnset = performance.now();
        loadStudySessionData();
        callback();
    });
}

function showNextComponent(componentData) { // move through elements of componentFlow list
    
    const componentOffset = performance.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    componentIndex += 1;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, componentData); // tell JATOS to start new component & log results from current component
}

function showSecondNextComponent(componentData) { // skip one component and show second-next one (needed only if all quiz questions correct)
    
    const componentOffset = performance.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    componentIndex += 2;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, componentData); // tell JATOS to start new component & log results from current component
}

function restartComponentFlow(componentData) { // restart at beginning if any wrong answer on quiz
    
    const componentOffset = performance.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    componentIndex = 0;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, componentData); // tell JATOS to start new component & log results from current component
}

function endComponentFlow(componentData) { // end flow (called in outro)

    const componentOffset = performance.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    // Redirect to RedCap
    let backLink = `https://redcap.zih.tu-dresden.de/redcap/surveys/?s=${backCode}`
    jatos.endStudyAndRedirect(backLink, componentData);
}


/*
 * State Configuration
 */

// input
// number = state number
// imageName = eg room1
// preChoiceTime = delay btw. cue onset & highlight in sec
// maxChoiceTime = time from highlight onset - latest key acceptance
// afterChoiceTime = reward onset - reward offset (depending on reward or no reward)
// reward = in euro, null if nothing happens
// nextState = number of next state
class OneChoiceState {

    constructor(number, imageName, preChoiceTime, maxChoiceTime, afterChoiceTimeNoReward, afterChoiceTimeReward, reward, nextState) {
        this.number = number;
        this.imageName = imageName;
        this.preChoiceTime = preChoiceTime;
        this.maxChoiceTime = maxChoiceTime;
        this.afterChoiceTimeNoReward = afterChoiceTimeNoReward;
        this.afterChoiceTimeReward = afterChoiceTimeReward;
        this.reward = reward;
        this.nextState = nextState;
    }
}

// input
// same as oneChoiceState 
// nextStateLeft = number of next state after left choice
// nextStateRight = number of next state after right choice
class TwoChoiceState {

    constructor(number, imageName, preChoiceTime, maxChoiceTime, afterChoiceTime, nextStateLeft, nextStateRight) {
        this.number = number;
        this.imageName = imageName;
        this.preChoiceTime = preChoiceTime;
        this.maxChoiceTime = maxChoiceTime;
        this.afterChoiceTime = afterChoiceTime;
        this.nextStateLeft = nextStateLeft;
        this.nextStateRight = nextStateRight;
    }
}

// test state: no successive state
// input
// same as twoChoiceState 
class TestState {

    constructor(number, imageName, preChoiceTime, maxChoiceTime, afterChoiceTime, nextStateLeft, nextStateRight) {
        this.number = number;
        this.imageName = imageName;
        this.preChoiceTime = preChoiceTime;
        this.maxChoiceTime = maxChoiceTime;
        this.afterChoiceTime = afterChoiceTime;
        this.nextStateLeft = nextStateLeft;
        this.nextStateRight = nextStateRight;
    }
}

// define how many trials start in which state  (not shuffled yet)
function defineLearningPhaseStartStates(correctFirstStateActionLearning) { 
    let startStatesFirstSection = Array(2).fill(1);

    let startStatesSecondSection = [
        Array(2).fill(1),
        Array(2).fill(2),
        Array(2).fill(3),
        Array(2).fill(4),
        Array(2).fill(5),
        Array(2).fill(6),
        Array(2).fill(7),
        Array(2).fill(8),
        Array(2).fill(9)
    ];

    let startStatesThirdSection = function() {

        if (correctFirstStateActionLearning == "right") {
            return [
                Array(6).fill(1),
                Array(8).fill(2),
                Array(4).fill(3),
            ];
        }
        else {
            return [
                Array(6).fill(1),
                Array(4).fill(2),
                Array(8).fill(3),
            ];
        }
    
    }();
    

    let flattenedStartStatesSecondSection = [].concat.apply([], startStatesSecondSection); // flatten: 1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,5 etc.
    let shuffledStartStatesSecondSection = shuffle(flattenedStartStatesSecondSection);


    let flattenedStartStatesThirdSection = [].concat.apply([], startStatesThirdSection); // flatten: 1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,5 etc.
    let shuffledStartStatesThirdSection = shuffle(flattenedStartStatesThirdSection);

    let allStartStates = startStatesFirstSection.concat(shuffledStartStatesSecondSection, shuffledStartStatesThirdSection);

    return allStartStates;
};




/*
 * Run experiment
 */

// within trial: function to draw screen for a state
// input
// stateNumber = state to be shown
// states = list of states defined in component
// trialResults = empty array to append results onto
// trialResultHandler = what to do after single trial finished
function configure(stateNumber, states, trialResults, trialResultHandler) {

    const state = states.find(function (state) { // find state number in list of states (according to number not position)
        return state.number == stateNumber;
    });
    
    const image = document.getElementById("image");
    setImageFromEnvironment("image", state.imageName);
    image.style.opacity = 1;

    // wait for a choice to be made
    doAfter(state.preChoiceTime, function() { // after delay defined per state, do...

        setImageFromEnvironment("image", `${state.imageName}_highlighted`); // show same image with highlighted options

        let didMakeChoice = false; // no choice made yet

        // one choice states
        if (state instanceof OneChoiceState) { 
            enableOneChoiceInput(function(RT) {
                didMakeChoice = true; // valid choice made
                setImageFromEnvironment("image", `${state.imageName}_selected`); // set selected image

                // rewarded trial
                if (state.reward) {
                    let rewardImage = document.getElementById("reward"); // we want to write sth into reward_image in body
                    rewardImage.src = `${getImagesPath()}/${state.reward}_euro.png`; // get image according to reward
                    rewardImage.style.opacity = 1; // set transparency (opacity 1 = transparency 0)

                    doAfter(state.afterChoiceTimeReward, function() { // after reward offset
                        rewardImage.style.opacity = 0; // hide image
                        rewardImage.src = `${getImagesPath()}/blank.png`;

                        if (state.nextState == null) {
                            fadeOut(image, function() {
                                trialResultHandler(trialResults, true);
                            });
                        }
                        else {
                            configure(state.nextState, states, trialResults, trialResultHandler);
                        }
                    });
                }

                // non-rewarded trial
                else {
                    doAfter(state.afterChoiceTimeNoReward, function() { // when last state per trial reached: handle results
                        if (state.nextState == null) {
                            fadeOut(image, function() {
                                trialResultHandler(trialResults, true);
                            });
                        }
                        else {
                            configure(state.nextState, states, trialResults, trialResultHandler); // as long as last state not reached yet: call configure again
                        }
                    });

                }

                trialResults.push({'state':stateNumber, 'valid_choice':didMakeChoice, 'RT':RT}); // log results

            });
        }

        // two choice states
        else if (state instanceof TwoChoiceState) {
            enableTwoChoiceInput(function(input, RT) {
                didMakeChoice = true; // valid choice made

                if (input == TwoChoiceInput.Left) {
                    setImageFromEnvironment("image", `${state.imageName}_left`); // set selected image

                    doAfter(state.afterChoiceTime, function() {
                        configure(state.nextStateLeft, states, trialResults, trialResultHandler); // move to next state's image
                    });
                }
                else if (input == TwoChoiceInput.Right) {
                    setImageFromEnvironment("image", `${state.imageName}_right`);

                    doAfter(state.afterChoiceTime, function() {
                        configure(state.nextStateRight, states, trialResults, trialResultHandler);
                    });
                }

                trialResults.push({'state':stateNumber, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT}); // log results

            });
        }

        // test state
        else if (state instanceof TestState) {
            enableTwoChoiceInput(function(input, RT) {
                didMakeChoice = true; // valid choice made

                if (input == TwoChoiceInput.Left) {
                    setImageFromEnvironment("image", `${state.imageName}_left`); // set selected image
                }
                else if (input == TwoChoiceInput.Right) {
                    setImageFromEnvironment("image", `${state.imageName}_right`);
                }

                doAfter(state.afterChoiceTime, function() {
                    fadeOut(image, function() {
                        trialResultHandler(trialResults, true);
                    });
                });

                trialResults.push({'state':stateNumber, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT});

            });
        }

        // define time to show warning message
        const overlayTime = function() {
            if (state instanceof OneChoiceState) {
                return state.afterChoiceTimeNoReward;
            }
            else {
                return state.afterChoiceTime;
            }
        }(); // add brackets to call function immediately

        doAfter(state.maxChoiceTime, function() {

            jatos.removeOverlay(); //remove wrong key overlay if present

            if (!didMakeChoice) { // if no valid choice recorded in time
                disableInput(); // disable any further input

                jatos.showOverlay({
                    text: "Zu langsam!",
                    showImg: false,
                    style: `
                        font-family: "Open Sans", Helvetica, sans-serif;
                        font-size: 20pt;
                        padding: 1em;
                        padding-top: 0.8em;
                        opacity: 1;
                        color: white;
                        background-color: rgba(208, 52, 44, 0.9);
                        border-radius: 3pt;
                        text-shadow: none;
                    `
                });

                doAfter(overlayTime, function() {
                    jatos.removeOverlay();

                    fadeOut(image, function() {
                        trialResultHandler(trialResults, false);
                    });

                });

                trialResults.push({'state':stateNumber, 'valid_choice':didMakeChoice}); // log results

            }

        });

    });

}

// function to run trials per component
// input
// initialStateNumbers = list of states from which to start per trial
// states = list of states defined in component
// aggregateResults = empty array to append results onto
// aggreagateResultHandler = what to do after all trials finished (usually showNextComponent)
function runTrials(trialIndex, initialStateNumbers, states, aggregateResults, aggregateResultHandler) { 

    configure(initialStateNumbers[trialIndex-1], states, [], function(trialResults, successfulTrial) {

        aggregateResults.push({'trial':trialIndex, trialResults}); // push trial results no matter if successful or not
    
        if (successfulTrial) {
            trialIndex += 1;
        }

        doAfter(ITI, function() {
            if (trialIndex-1 < initialStateNumbers.length) { // if more trials to run, call runTrial again
                runTrials(trialIndex, initialStateNumbers, states, aggregateResults, aggregateResultHandler);
            }
            else {
                aggregateResultHandler();
            }

        });
        
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
    Space: " ",
    Enter: "Enter"
};

const TwoChoiceInput = { // left and right choice, independent of which keys are used
    Left: "left",
    Right: "right"
};

function enableOneChoiceInput(callback) { // allowed keys for 1-choice states
    
    const cueOnset = performance.now(); // log time at cue onset

    document.onkeydown = function(event) {
        if (event.key == Keyboard.Space) { // change input key here
            const responseOnset = performance.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(RT); // call what I put in as callback function
        }
        else {
            jatos.showOverlay({
                text: "Nur Leerzeichen gültig!",
                showImg: false,
                style: `
                    font-family: "Open Sans", Helvetica, sans-serif;
                    font-size: 20pt;
                    padding: 1em;
                    padding-top: 0.8em;
                    opacity: 1;
                    color: white;
                    background-color: rgba(208, 52, 44, 0.9);
                    border-radius: 3pt;
                    text-shadow: none;
                `
            });

            doAfter(0.8, function() {
                jatos.removeOverlay();
            });
        }
    };
}

function enableTwoChoiceInput(callback) { // allowed keys for 2-choice states

    const cueOnset = performance.now(); // log time at cue onset

    document.onkeydown = function(event) {
        if (event.key == Keyboard.F) { // change input key here
            const responseOnset = performance.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Left, RT); // execute function defined as callback function with input TwoChoioceInput.Left
        }
        else if (event.key == Keyboard.J) { // change input key here
            const responseOnset = performance.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Right, RT); // execute function defined as callback function with input TwoChoioceInput.Right
        }
        else {
            jatos.showOverlay({
                text: "Nur F oder J gültig!",
                showImg: false,
                style: `
                    font-family: "Open Sans", Helvetica, sans-serif;
                    font-size: 20pt;
                    padding: 1em;
                    padding-top: 0.8em;
                    opacity: 1;
                    color: white;
                    background-color: rgba(208, 52, 44, 0.9);
                    border-radius: 3pt;
                    text-shadow: none;
                `
            });

            doAfter(0.8, function() {
                jatos.removeOverlay();
            });
        }
    };
}

function disableInput() {
    document.onkeydown = null;
}




/*
 * Utilities
 */

function preloadImages() { // preload images so that there are no delays 
    const rootImageNames = jatos.studyJsonInput["root_image_names"];

    rootImageNames.forEach(function(imageName) {
        const image = new Image();
        image.src = `${getImagesPath()}/${imageName}.png`;
    });

    const environmentImageNames = jatos.studyJsonInput["environment_image_names"];

    environmentImageNames.forEach(function(imageName) {
        Environments.forEach(function(environment) {
            const image = new Image();
            image.src = `${getImagesPath()}/${environment}/${imageName}.png`;
        });
    });
}

function setImageFromEnvironment(id, imageName) { // set image to show based on environment mapping
    const image = document.getElementById(id);
    image.src = `${getEnvironmentPath()}/${imageName}.png`;
}

function getImagesPath() {
    return jatos.studyJsonInput["images_path"];
}

function getEnvironmentPath() { // get path for component images
    const component = componentFlow[componentIndex];
    const environment = environmentMap[component]; // what color for current comnponent?

    return `${getImagesPath()}/${environment}`;
}

function doAfter(timeInterval, callback) { // execute function defined by callback after delay
    setTimeout(callback, timeInterval * 1000);
}

function fadeOut(element, callback) { // fadeout
    const root = document.documentElement;
    root.style.setProperty('--fadeout-time', `${fadeoutTime-0.2}s`);

    element.classList.add("fade_out");

    doAfter(fadeoutTime-0.1, function() {
        element.classList.remove("fade_out");
        element.style.opacity = 0;

        if (element instanceof HTMLImageElement) {
            element.src = `${getImagesPath()}/blank.png`;
        }

        doAfter(0.1, function() {
            callback();
        });
    });
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

function compareArrays(a, b) {
    if (a.length != b.length) {
        return false;
    }

    for (let i = 0; i < a.length; i += 1) {
        if (a[i] != b[i]) {
            return false;
        }
    }

    return true;
}


/*
 * Static Components
 */
const StaticComponents = {
    Intro1: "intro1",
    Tutorial: "tutorial",
    Intro2: "intro2",
    Quiz: "quiz",
    QuizWrong: "quiz_wrong",
    Intro3: "intro3",
    Outro: "outro"
};




/*
 * Environments
 */

const Environments = [ // all envs incl tutorial env
    "light_blue",
    "messy_green",
    "orange_tile",
    "red_brown",
    "white_modern",
    "blue_floral"
];




/*
 * Phases
 */

const Phases = [
    "learning",
    "relearning",
    "test"
];




/*
 * Variations
 */
const Variations = [
    {
        "A1": [
            {"reward":      "light_blue"},
            {"transition":  "blue_floral"},
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"},
        ]
    },
    {
        "A2": [
            {"reward":      "blue_floral"},
            {"transition":  "orange_tile"},
            {"goal-state":  "red_brown"},
            {"control":     "light_blue"}
        ]
    },
    {
        "A3": [
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"},
            {"goal-state":  "light_blue"},
            {"control":     "blue_floral"}
        ]
    },
    {
        "A4": [
            {"reward":      "red_brown"},
            {"transition":  "light_blue"},
            {"goal-state":  "blue_floral"},
            {"control":     "orange_tile"}
        ]
    },
    {
        "B1": [
            {"transition":  "light_blue"},
            {"goal-state":  "blue_floral"},
            {"control":     "orange_tile"},
            {"reward":      "red_brown"},
        ]
    },
    {
        "B2": [
            {"transition":  "blue_floral"},
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"},
            {"reward":      "light_blue"}
        ]
    },
    {
        "B3": [
            {"transition":  "orange_tile"},
            {"goal-state":  "red_brown"},
            {"control":     "light_blue"},
            {"reward":      "blue_floral"}
        ]
    },
    {
        "B4": [
            {"transition":  "red_brown"},
            {"goal-state":  "light_blue"},
            {"control":     "blue_floral"},
            {"reward":      "orange_tile"}
        ]
    },
    {
        "C1": [
            {"goal-state":  "light_blue"},
            {"control":     "blue_floral"},
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"},
        ]
    },
    {
        "C2": [
            {"goal-state":  "blue_floral"},
            {"control":     "orange_tile"},
            {"reward":      "red_brown"},
            {"transition":  "light_blue"}
        ]
    },
    {
        "C3": [
            {"goal-state":  "orange_tile"},
            {"control":     "red_brown"},
            {"reward":      "light_blue"},
            {"transition":  "blue_floral"}
        ]
    },
    {
        "C4": [
            {"goal-state":  "red_brown"},
            {"control":     "light_blue"},
            {"reward":      "blue_floral"},
            {"transition":  "orange_tile"}
        ]
    },
    {
        "D1": [
            {"control":     "light_blue"},
            {"reward":      "blue_floral"},
            {"transition":  "orange_tile"},
            {"goal-state":  "red_brown"}
        ]
    },
    {
        "D2": [
            {"control":     "blue_floral"},
            {"reward":      "orange_tile"},
            {"transition":  "red_brown"},
            {"goal-state":  "light_blue"}
        ]
    },
    {
        "D3": [
            {"control":     "orange_tile"},
            {"reward":      "red_brown"},
            {"transition":  "light_blue"},
            {"goal-state":  "blue_floral"}
        ]
    },
    {
        "D4": [
            {"control":     "red_brown"},
            {"reward":      "light_blue"},
            {"transition":  "blue_floral"},
            {"goal-state":  "orange_tile"}
        ]
    }
];


// callback is a function that is passed into another function so that it can be executed after waiting for asynchronous event
