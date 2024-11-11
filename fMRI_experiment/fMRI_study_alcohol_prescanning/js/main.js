/*
 * main.js
 */




/*
 * Timing variables
 */

const preChoiceTime = 0.5; // time in state without highlighted choice options
const maxOneChoiceTime = 2; // max time in one choice state with highlighted choice option - ended as soon as valid key pressed
const maxTwoChoiceTime = 3; // max time in two choice state with highlighted choice option - ended as soon as valid key pressed
const maxTestChoiceTime = 15; // max time with highlighted options in test phase
const afterChoiceTimeNoReward = 2.0; // time after valid choice with no reward
const afterChoiceTimeReward = 2.5; // time after valid choice with reward presentation
const fadeoutTime = 0.5; // fadeout duration after each trial (and intro/outro component)
const ITI = 0.5; // inter trial interval
const viewingTime = 2; // time to show one state during tutorial viewing block


/*
 * Study Session Data
 */

let participantID = null; // participant ID generated in RedCap
let runningID = null; // running ID generated in RedCap
let backCode = null; // code leading back to individual RedCap questionnaires when appended to RedCap backLink
let variationID = null; // which condition order and matching of condition and environment (see 'variations' at bottom of main.js)
let environmentMap = {
    "tutorial": "tapas",
    "tutorial-viewing": "tapas"
}; // mapping btw component & environment; environment of tutorial is always the same
let componentFlow = []; // list of component titles (reward learning etc.)
let componentIndex = 0; // current component index
let componentOnset = null; // onset time for each component
let drink = null;



/*
 * Component Flow
 */

function prepareTask() { // prepare list of what we should show

    preloadImages();

    // read out link components
    // example link: https://studies.bccn-berlin.de/publix/HG5A1FTtOIL?participant=30620126hqIHzHP2GhTvxYt
    //let urlQuery = jatos.urlQueryParameters.participant;
    let urlQuery = '30620126hqIHzHP2GhTvxYt';
    participantID = Number(urlQuery.substr(0,4)); 
    runningID = Number(urlQuery.substr(4,3));
    backCode = urlQuery.substr(7,urlQuery.length-7);

    jatos.studySessionData = { // save session data to pass to other components
        "participant_id": participantID,
        "running_id": runningID,
        "back_code": backCode,
        "variation_id": variationID,
        "environment_map": environmentMap,
        "component_flow": componentFlow,
        "component_index": componentIndex,
        "drink": drink
    };

    componentOnset = Date.now();
}

function prepareComponentFlow() { // prepare list of what we should show

    const keys_1 = ["A1", "B1", "C1", "D1", "E1"];
    const keys_0 = ["A2", "B2", "C2", "D2", "E2"];
    const keys_3 = ["A3", "B3", "C3", "D3", "E3"];
    const keys_2 = ["A4", "B4", "C4", "D4", "E4"];

    if (keys_1.includes(variationID)) {
        const correctFirstStateActionLearning = shuffle(["left", "right"]); // TODO randomize which state 1 action is correct after learning
        jatos.studySessionData["control"] = null;
        jatos.studySessionData["reward"] = {"correct_first_state_action_learning": correctFirstStateActionLearning[1]};
        jatos.studySessionData["goal-state"] = null;
    } else if (keys_2.includes(variationID)) {
        const correctFirstStateActionLearning = shuffle(["left", "right"]); // TODO randomize which state 1 action is correct after learning
        jatos.studySessionData["control"] = {"correct_first_state_action_learning": correctFirstStateActionLearning[0]};
        jatos.studySessionData["reward"] = {"correct_first_state_action_learning": correctFirstStateActionLearning[1]};
        jatos.studySessionData["goal-state"] = null;
    } else if (keys_3.includes(variationID)) {
        const correctFirstStateActionLearning = shuffle(["left", "right", "left"]); // TODO randomize which state 1 action is correct after learning
        jatos.studySessionData["control"] = {"correct_first_state_action_learning": correctFirstStateActionLearning[0]};
        jatos.studySessionData["reward"] = {"correct_first_state_action_learning": correctFirstStateActionLearning[1]};
        jatos.studySessionData["goal-state"] = {"correct_first_state_action_learning": correctFirstStateActionLearning[2]};
    } else {
        jatos.studySessionData["control"] = null;
        jatos.studySessionData["reward"] = null;
        jatos.studySessionData["goal-state"] = null;
    }

    componentFlow.push( // add StaticComponents to componentFlow array
        StaticComponents.EnterVariation,
        StaticComponents.Intro1, 
        StaticComponents.FloorPlan,
        StaticComponents.DrinkSelection,
        StaticComponents.Intro2,  
        StaticComponents.Tutorial, 
        StaticComponents.Intro3, 
        StaticComponents.Quiz, 
        StaticComponents.QuizWrong,
        StaticComponents.Intro4,
        StaticComponents.TutorialViewing
    ); 

    const variation = Variations.find(variation => variation.hasOwnProperty(jatos.studySessionData['variation_id']))
    //const variation = Variations[runningID % Variations.length]; // get element of Variations based on runningID
    variationID = Object.keys(variation)[0]; // get e.g. A1, A2 etc. key
    const entries = variation[variationID]; // get content of variation element e.g. A1

    if (entries.length > 0) { // if there are conditions to be performed before scanning

        componentFlow.push(StaticComponents.Intro5Outside); // push outro

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

    } else {

        componentFlow.push(StaticComponents.Intro5Inside); // push outro

    }

    componentOnset = Date.now();
}

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
        componentOnset = Date.now();
        loadStudySessionData();
        console.log(componentFlow[componentIndex]);
        callback();
    });
}

function showNextComponent(componentData) { // move through elements of componentFlow list
    
    const componentOffset = Date.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    componentIndex += 1;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, componentData); // tell JATOS to start new component & log results from current component
}

function showSecondNextComponent(componentData) { // skip one component and show second-next one (needed only if all quiz questions correct)
    
    const componentOffset = Date.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    componentIndex += 2;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, componentData); // tell JATOS to start new component & log results from current component
}

function restartComponentFlow(componentData) { // restart at beginning if any wrong answer on quiz
    
    const componentOffset = Date.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    componentIndex = 0;
    jatos.studySessionData["component_index"] = componentIndex;

    const componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle, componentData); // tell JATOS to start new component & log results from current component
}

function endComponentFlow(componentData) { // end flow (called in outro)

    const componentOffset = Date.now();
    const componentDuration = componentOffset - componentOnset;
    componentData['component_duration'] = componentDuration;

    jatos.endStudy(componentData);
}


/*
 * State Configuration
 */

// input
// name = state name
// imageName = eg room1
// preChoiceTime = delay btw. cue onset & highlight in sec
// maxChoiceTime = time from highlight onset - latest key acceptance
// afterChoiceTime = reward onset - reward offset (depending on reward or no reward)
// reward = in euro, null if nothing happens
// nextState = name of next state
class OneChoiceState {

    constructor(name, imageName, preChoiceTime, maxChoiceTime, afterChoiceTimeNoReward, afterChoiceTimeReward, reward, nextState) {
        this.name = name;
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
// nextStateLeft = name of next state after left choice
// nextStateRight = name of next state after right choice
class TwoChoiceState {

    constructor(name, imageName, preChoiceTime, maxChoiceTime, afterChoiceTime, nextStateLeft, nextStateRight) {
        this.name = name;
        this.imageName = imageName;
        this.preChoiceTime = preChoiceTime;
        this.maxChoiceTime = maxChoiceTime;
        this.afterChoiceTime = afterChoiceTime;
        this.nextStateLeft = nextStateLeft;
        this.nextStateRight = nextStateRight;
    }
}

// define how many trials start in which state  (not shuffled yet)
function defineLearningPhaseStartStates() { 

    let startStatesFirstSection = [
        Array(1).fill("1LeftTo2Left"),
        Array(1).fill("1LeftTo2Right"),
        Array(1).fill("1RightTo3Left"),
        Array(1).fill("1RightTo3Right"),
    ];

    let startStatesSecondSection = [
        Array(20).fill("1")
    ];

    let flattenedStartStatesFirstSection = [].concat.apply([], startStatesFirstSection);
    let shuffledStartStatesFirstSection = shuffle(flattenedStartStatesFirstSection);

    let flattenedStartStatesSecondSection = [].concat.apply([], startStatesSecondSection); // flatten: 1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,5 etc.
    
    let allStartStates = shuffledStartStatesFirstSection.concat(flattenedStartStatesSecondSection);

    return allStartStates;
};

/*
 * Run experiment
 */

// within trial: function to draw screen for a state
// input
// stateName = state to be shown
// states = list of states defined in component
// trialResults = empty array to append results onto
// trialResultHandler = what to do after single trial finished
function configure(stateName, states, trialResults, trialResultHandler) {

    const state = states.find(function (state) { // find state name in list of states (according to name not position)
        return state.name == stateName;
    });
    console.log(state.name)
    console.log(stateName)

    const image = document.getElementById("image");
    image.removeAttribute("src");
    image.style.opacity = 1;
    setImageFromEnvironment("image", `${state.imageName}`, stateName);

    drink = jatos.studySessionData["drink"]; // which drink should be used as reward
    console.log(drink)

    // wait for a choice to be made
    doAfter(state.preChoiceTime, function() { // after delay defined per state, do...

        let didMakeChoice = false; // no choice made yet

        // two choice states
        if (state instanceof TwoChoiceState) {

            // forced choice left
            if (state.nextStateLeft != null && state.nextStateRight == null) {

                setImageFromEnvironment("image", `${state.imageName}_highlighted_left`, stateName); // show same image with highlighted options

                enableTwoChoiceInputLeft(function(input, RT) {
                    didMakeChoice = true; // valid choice made
                    setImageFromEnvironment("image", `${state.imageName}_left`, stateName); // set selected image

                    doAfter(state.afterChoiceTime, function() {
                        configure(state.nextStateLeft, states, trialResults, trialResultHandler); // move to next state's image
                    });
                    
                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT}); // log results
                });
            }
            
            // forced choice right
            else if (state.nextStateLeft == null && state.nextStateRight != null) {

                setImageFromEnvironment("image", `${state.imageName}_highlighted_right`, stateName); // show same image with highlighted options

                enableTwoChoiceInputRight(function(input, RT) {
                    didMakeChoice = true; // valid choice made
                    setImageFromEnvironment("image", `${state.imageName}_right`, stateName); // set selected image

                    doAfter(state.afterChoiceTime, function() {
                        configure(state.nextStateRight, states, trialResults, trialResultHandler); // move to next state's image
                    });
                    
                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT}); // log results
                });
            }
            
            // end trial during test phase
            else if (state.nextStateLeft == null && state.nextStateRight == null) {

                setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName); // show same image with highlighted options

                enableTwoChoiceInput(function(input, RT) {
                    didMakeChoice = true; // valid choice made

                    if (input == TwoChoiceInput.Left) {
                        setImageFromEnvironment("image", `${state.imageName}_left`, stateName); // set selected image
                    }
                    else if (input == TwoChoiceInput.Right) {
                        setImageFromEnvironment("image", `${state.imageName}_right`, stateName);
                    }

                    doAfter(state.afterChoiceTime, function() {
                        fadeOut(image, function() {
                            trialResultHandler(trialResults, true);
                        });
                    });

                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT}); // log results
                
                });

            }

            // free choice
            else {

                setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName); // show same image with highlighted options

                enableTwoChoiceInput(function(input, RT) {
                    didMakeChoice = true; // valid choice made

                    if (input == TwoChoiceInput.Left) {
                        setImageFromEnvironment("image", `${state.imageName}_left`, stateName); // set selected image

                        doAfter(state.afterChoiceTime, function() {
                            configure(state.nextStateLeft, states, trialResults, trialResultHandler);
                        });
                    }
                    else if (input == TwoChoiceInput.Right) {
                        setImageFromEnvironment("image", `${state.imageName}_right`, stateName);

                        doAfter(state.afterChoiceTime, function() {
                            configure(state.nextStateRight, states, trialResults, trialResultHandler);
                        });
                    }

                    

                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT}); // log results

                });
            }   
        }

        // one choice states
        else if (state instanceof OneChoiceState) { 

            setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName); // show same image with highlighted options

            enableOneChoiceInput(function(RT) {
                didMakeChoice = true; // valid choice made
                setImageFromEnvironment("image", `${state.imageName}_selected`, stateName); // set selected image

                // rewarded trial
                if (state.reward) {
                    let rewardImage = document.getElementById("reward"); // we want to write sth into reward_image in body
                    rewardImage.src = `${getImagesPath()}/${state.reward}_${drink}.png`; // get image according to reward

                    doAfter(state.afterChoiceTimeReward, function() { // after reward offset
                        rewardImage.removeAttribute("src");

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

                trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'RT':RT}); // log results

            });
        }

        // define time to show too slow warning message
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

                trialResults.push({'state':stateName, 'valid_choice':didMakeChoice}); // log results

            }

        });

    });

}

// function to run trials per component
// input
// initialStateNames = list of states from which to start per trial
// states = list of states defined in component
// aggregateResults = empty array to append results onto
// aggreagateResultHandler = what to do after all trials finished (usually showNextComponent)
function runTrials(trialIndex, initialStateNames, states, aggregateResults, aggregateResultHandler) { 

    configure(initialStateNames[trialIndex-1], states, [], function(trialResults, successfulTrial) {

        aggregateResults.push({'trial':trialIndex, trialResults}); // push trial results no matter if successful or not
    
        if (successfulTrial) {
            trialIndex += 1;
        }

        doAfter(ITI, function() {
            if (trialIndex-1 < initialStateNames.length) { // if more trials to run, call runTrial again
                runTrials(trialIndex, initialStateNames, states, aggregateResults, aggregateResultHandler);
            }
            else {
                aggregateResultHandler();
            }

        });
        
    });

}


// function to run single viewing
// input
// initialStateNames = list of states from which to start per trial
// states = list of states defined in component
// aggregateResults = empty array to append results onto
// aggreagateResultHandler = what to do after this trial is finished
function configureViewing(stateName, questionTrial, states, viewingResults, viewingResultsHandler) {

    const state = states.find(function (state) { // find state name in list of states (according to name not position)
        return state.name == stateName;
    });

    const image = document.getElementById("image");
    image.removeAttribute("src");
    image.style.opacity = 1;

    const images_highlighted = ["4Viewing", "5Viewing", "6Viewing", "7Viewing", "8Viewing", "9Viewing", "10Viewing"];
    const images_highlighted_left = ["1LeftViewing", "2LeftViewing", "3LeftViewing"];
    const images_highlighted_right = ["1RightViewing", "2RightViewing", "3RightViewing"];

    if (images_highlighted.includes(stateName)) {
        setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName);
    } else if (images_highlighted_left.includes(stateName)) {
        setImageFromEnvironment("image", `${state.imageName}_highlighted_left`, stateName);
    } else if (images_highlighted_right.includes(stateName)) {
        setImageFromEnvironment("image", `${state.imageName}_highlighted_right`, stateName);
    }

    // initialize timing and selection variables
    let questionOnset = null;
    let responseOnset = null;
    let RT = null;
    let selection = null;
    let didMakeChoice = false;

    doAfter(viewingTime, function() {

        image.style.display = "none" ;

        if (questionTrial === 1) {
            // define text for question ITIs
            const questionText = [
                    `Wie viele Gläser Alkohol können Sie maximal auf dem Weg erhalten, der der letzten Handlung folgt?
                    <br>
                    ('0' - '4')`
                ];
            const optionLeftLeftText = [`0`];
            const optionLeftMiddleText = [`1`];
            const optionRightMiddleText = [`2`];
            const optionRightRightText = [`3`];

            // display elements
            const questionScreen = document.getElementById("drink_selection_screen");
            questionScreen.style.display = ""; // make visible

            const question = document.getElementById("question");
            question.innerHTML = questionText[0];
            const optionLeftLeft = document.getElementById("option_leftleft");
            optionLeftLeft.innerHTML = optionLeftLeftText[0]
            const optionLeftMiddle = document.getElementById("option_leftmiddle");
            optionLeftMiddle.innerHTML = optionLeftMiddleText[0]
            const optionRightMiddle = document.getElementById("option_rightmiddle");
            optionRightMiddle.innerHTML = optionRightMiddleText[0]
            const optionRightRight = document.getElementById("option_rightright");
            optionRightRight.innerHTML = optionRightRightText[0]

            questionOnset = Date.now();
            
            document.onkeydown = function(event) { // navigation through intro

                disableInput(); // disable any further input

                if (event.key == Keyboard.Zero) {
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "0";
                    optionLeftLeft.classList.add("quiz_option_selected");
                    optionLeftMiddle.classList.remove("quiz_option_selected");
                    optionRightMiddle.classList.remove("quiz_option_selected");
                    optionRightRight.classList.remove("quiz_option_selected");
                }
                else if (event.key == Keyboard.One) {
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "1";
                    optionLeftLeft.classList.remove("quiz_option_selected");
                    optionLeftMiddle.classList.add("quiz_option_selected");
                    optionRightMiddle.classList.remove("quiz_option_selected");
                    optionRightRight.classList.remove("quiz_option_selected");
                }
                else if (event.key == Keyboard.Two) {
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "2";
                    optionLeftLeft.classList.remove("quiz_option_selected");
                    optionLeftMiddle.classList.remove("quiz_option_selected");
                    optionRightMiddle.classList.add("quiz_option_selected");
                    optionRightRight.classList.remove("quiz_option_selected");
                    
                } else if (event.key == Keyboard.Three) {
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "3";
                    optionLeftLeft.classList.remove("quiz_option_selected");
                    optionLeftMiddle.classList.remove("quiz_option_selected");
                    optionRightMiddle.classList.remove("quiz_option_selected");
                    optionRightRight.classList.add("quiz_option_selected");
                }

            };

            doAfter(maxTwoChoiceTime, function() {

                optionLeftLeft.classList.remove("quiz_option_selected");
                optionLeftMiddle.classList.remove("quiz_option_selected");
                optionRightMiddle.classList.remove("quiz_option_selected");
                optionRightRight.classList.remove("quiz_option_selected");
                questionScreen.style.display = "none"; // make invisible

                console.log(selection);
                viewingResults.push({'state':stateName, 'question_trial': questionTrial, 'valid_choice':didMakeChoice, 'selection': selection, 'RT': RT}); // log results
                viewingResultsHandler(viewingResults, true);

            })

        } else {

            console.log(selection);
            viewingResults.push({'state':stateName, 'question_trial': questionTrial, 'valid_choice':didMakeChoice, 'selection': selection, 'RT': RT}); // log results
            viewingResultsHandler(viewingResults, true);

        };

    });

};


// function to run all Viewings per component
// input
// initialStateNames = list of states from which to start per trial
// states = list of states defined in component
// aggregateResults = empty array to append results onto
// aggreagateResultHandler = what to do after all trials finished (usually showNextComponent)
function runViewing(viewingStateIndex, initialStateNames, questionTrials, states, aggregateViewingResults, aggregateViewingResultsHandler) {

    // show question on this trial or not
    questionTrial = questionTrials[viewingStateIndex-1];

    configureViewing(initialStateNames[viewingStateIndex-1], questionTrial, states, [], function(viewingResults) {

        aggregateViewingResults.push({'viewing':viewingStateIndex, viewingResults}); // push trial results no matter if successful or not

        viewingStateIndex += 1;

        doAfter(ITI, function() {
            if (viewingStateIndex-1 < initialStateNames.length) { // if more trials to run, call runTrial again
                runViewing(viewingStateIndex, initialStateNames, questionTrials, states, aggregateViewingResults, aggregateViewingResultsHandler);
            }
            else {
                aggregateViewingResultsHandler();
            };

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
    DownArrow: "ArrowDown",
    Space: " ",
    Enter: "Enter",
    Zero: "0",
    One: "1",
    Two: "2",
    Three: "3"
};

const TwoChoiceInput = { // left and right choice, independent of which keys are used
    Left: "left",
    Right: "right"
};

function enableOneChoiceInput(callback) { // allowed keys for 1-choice states
    
    const cueOnset = Date.now(); // log time at cue onset

    document.onkeydown = function(event) {
        if (event.key == Keyboard.Space) { // change input key here
            const responseOnset = Date.now();
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

    const cueOnset = Date.now(); // log time at cue onset

    document.onkeydown = function(event) {
        if (event.key == Keyboard.F) { // change input key here
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Left, RT); // execute function defined as callback function with input TwoChoioceInput.Left
        }
        else if (event.key == Keyboard.J) { // change input key here
            const responseOnset = Date.now();
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

function enableTwoChoiceInputLeft(callback) { // allowed keys for 2-choice states

    const cueOnset = Date.now(); // log time at cue onset

    document.onkeydown = function(event) {
        if (event.key == Keyboard.F) { // change input key here
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Left, RT); // execute function defined as callback function with input TwoChoioceInput.Left
        }
        else {
            jatos.showOverlay({
                text: "Nur F gültig!",
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

function enableTwoChoiceInputRight(callback) { // allowed keys for 2-choice states

    const cueOnset = Date.now(); // log time at cue onset

    document.onkeydown = function(event) {
        if (event.key == Keyboard.J) { // change input key here
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Right, RT); // execute function defined as callback function with input TwoChoioceInput.Right
        }
        else {
            jatos.showOverlay({
                text: "Nur J gültig!",
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
            image.src = `${getImagesPath()}/${environment}/${imageName}.jpg`;
        });
    });
}

function setImageFromEnvironment(id, imageName, stateName) { // set image to show based on environment mapping

    const image = document.getElementById(id);
    const imageContainer = document.getElementById('image_container');
    const rewardImage = document.getElementById("reward"); 

    image.style.display = ""; // show image again if it was removed before

    console.log(stateName);

    if (stateName == "2" || stateName == "2Left" || stateName == "2LeftViewing" || stateName == "2Right" || stateName == "2RightViewing") {
        // Middle left
        console.log("Middle left");
        imageContainer.style.width = "70%";
        imageContainer.style.left = "15%";
        image.style.marginLeft = "0px";
        image.style.marginRight = "auto";
        rewardImage.style.marginLeft = "0px";
        rewardImage.style.marginRight = "auto";
    } 
    else if (stateName == "3" || stateName == "3Left" || stateName == "3LeftViewing" || stateName == "3Right" || stateName == "3RightViewing") {
        // Middle right
        console.log("Middle right");
        imageContainer.style.width = "70%";
        imageContainer.style.left = "15%";
        image.style.marginLeft = "auto";
        image.style.marginRight = "0px";
        rewardImage.style.marginLeft = "auto";
        rewardImage.style.marginRight = "0px";
    } 
    else if (stateName == "4" || stateName == "4Viewing" || stateName == "7" || stateName == "7Viewing") {
        // Outer left
        console.log("Outer left");
        imageContainer.style.width = "90%";
        imageContainer.style.left = "5%";
        image.style.marginLeft = "0px";
        image.style.marginRight = "auto";
        rewardImage.style.marginLeft = "0px";
        rewardImage.style.marginRight = "auto";
    } 
    else if (stateName == "6" || stateName == "6Viewing" || stateName == "9" || stateName == "9Viewing") {
        // Outer right
        console.log("Outer right");
        imageContainer.style.width = "90%";
        imageContainer.style.left = "5%";
        image.style.marginLeft = "auto";
        image.style.marginRight = "0px";
        rewardImage.style.marginLeft = "auto";
        rewardImage.style.marginRight = "0px";
    }
    else if (imageContainer != null) {
        // Center
        console.log("Center");
        imageContainer.style.width = "100%";
        imageContainer.style.left = "0%";
        image.style.marginLeft = "auto";
        image.style.marginRight = "auto";
        rewardImage.style.marginLeft = "auto";
        rewardImage.style.marginRight = "auto";
    }

    image.src = `${getEnvironmentPath()}/${imageName}.jpg`;
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
            element.removeAttribute("src");
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
    EnterVariation: "enter-variation",
    Intro1: "intro1",
    FloorPlan: "floor-plan",
    DrinkSelection: "drink-selection",
    Intro2: "intro2",
    Tutorial: "tutorial",
    Intro3: "intro3",
    Quiz: "quiz",
    QuizWrong: "quiz_wrong",
    Intro4: "intro4",
    TutorialViewing: "tutorial-viewing",
    Intro5Outside: "intro5_startoutsidescanner",
    Intro5Inside: "intro5_startinscanner",
    Outro: "outro"
};


/*
 * Environments
 */

const Environments = [ // all envs incl tutorial env
    "alternative",
    "brauhaus",
    "fancy_green",
    "hip_purple",
    "sports_bar",
    "tapas"
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
            {"reward": "alternative"},
        ]
    },
    {
        "A2": [
        ]
    },
    {
        "A3": [
            {"goal-state": "alternative"},
            {"control": "brauhaus"},
            {"reward": "fancy_green"}
        ]
    },
    {
        "A4": [
            {"control": "alternative"},
            {"reward": "brauhaus"}
        ]
    },
    {
        "B1": [
            {"reward": "brauhaus"}
        ]
    },
    {
        "B2": [
        ]
    },
    {
        "B3": [
            {"goal-state": "brauhaus"},
            {"control": "hip_purple"},
            {"reward": "sports_bar"}
        ]
    },
    {
        "B4": [
            {"control": "brauhaus"},
            {"reward": "hip_purple"}
        ]
    },
    {
        "C1": [
            {"reward": "fancy_green"}
        ]
    },
    {
        "C2": [
        ]
    },
    {
        "C3": [
            {"goal-state": "fancy_green"},
            {"control": "sports_bar"},
            {"reward": "alternative"}
        ]
    },
    {
        "C4": [
            {"control": "fancy_green"},
            {"reward": "sports_bar"}
        ]
    },
    {
        "D1": [
            {"reward": "hip_purple"}
        ]
    },
    {
        "D2": [
        ]
    },
    {
        "D3": [
            {"goal-state": "hip_purple"},
            {"control": "sports_bar"},
            {"reward": "alternative"}
        ]
    },
    {
        "D4": [
            {"control": "hip_purple"},
            {"reward": "sports_bar"}
        ]
    },
    {
        "E1": [
            {"reward": "sports_bar"}
        ]
    },
    {
        "E2": [
        ]
    },
    {
        "E3": [
            {"goal-state": "sports_bar"},
            {"control": "alternative"},
            {"reward": "fancy_green"}
        ]
    },
    {
        "E4": [
            {"control": "sports_bar"},
            {"reward": "alternative"}
        ]
    }
];





// callback is a function that is passed into another function so that it can be executed after waiting for asynchronous event