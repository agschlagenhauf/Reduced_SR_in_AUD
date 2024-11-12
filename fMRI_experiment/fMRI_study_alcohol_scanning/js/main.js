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
const viewingTime = 2; // time to show one state during viewing block
// Exponential distribution with mean 3 and range 2-5 seconds, generated with R script
const viewingITI = shuffleNumbers(3.67, 2.86, 2.11, 2.74, 3.34, 2.31, 3.52, 2.74, 4.15, 2.69, 2, 3.5, 4.36, 2.08, 4.14, 2.58,
    2.63, 2.7, 4.56, 2.71, 2.51, 3.44, 2.41, 4.83, 2.72, 2.48, 4.74, 4.9, 3.38, 4.21, 3.06, 3.18, 2.87, 2.32, 2.69, 3.64, 3.27,
    3.42, 2.87, 3.81, 3.52, 3.74, 2.99, 3.45, 4.91, 2.62, 2.7, 2.72, 4.74, 2.14, 3.7, 2.18, 2.06, 4.07, 3.9, 3.15, 3.32, 2.28,
    3.15, 2.27, 3.73, 4.48, 4.18, 2.02, 2.11, 2.57, 4.94, 2.1, 2.26, 2.47, 2.65, 2.38, 4.35, 2.43, 2.74, 4.81, 3.49, 3.19, 2.83,
    3.53, 3.95, 3.96, 2.27, 2.04, 4.05, 2.45, 2.58, 3.93, 3.32, 3.1, 2.36, 3.13, 3.53, 2.45, 4.53, 2.51, 2.52, 4.9, 2.77, 2.21,
    4.41, 3.18, 3.54, 2.37, 3.2, 3.66, 4.04, 2.16, 3.56, 2.31, 3.77, 3.59, 4.04, 2.75, 2.72, 2.58, 4.68, 2.19, 2.24, 2.39, 4.79,
    2.53, 4.66, 4.05, 2.5, 3.35, 2.16, 2.33, 2.38, 4.02, 3.27, 4.74, 2.89, 2.32, 3.34, 4.32, 3.05, 4.17, 2.95, 4.81, 3.73, 2.46,
    2.98, 3.12, 3.4, 2.6, 3.9, 3.92, 2.46, 3.68, 2.22, 3.02, 2.62, 2.55, 2.25).concat(3);



/*
 * Study Session Data
 */

let participantID = null; // participant ID generated in RedCap
let runningID = null; // running ID generated in RedCap
let backCode = null; // code leading back to individual RedCap questionnaires when appended to RedCap backLink
let variationID = null; // which condition order and matching of condition and environment (see 'variations' at bottom of main.js)
let environmentMap = {
    "tutorial": "tapas"
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

    const correctFirstStateActionLearning = shuffle(["left", "right"]); // TODO randomize which state 1 action is correct after learning

    jatos.studySessionData["transition1"] = { // save session data to pass to other components
        "correct_first_state_action_learning": correctFirstStateActionLearning[0]
    };
    jatos.studySessionData["transition2"] = {
        "correct_first_state_action_learning": correctFirstStateActionLearning[1]
    };

    componentOnset = Date.now();
}

function prepareComponentFlow() { // prepare list of what we should show

    componentFlow.push( // add StaticComponents to componentFlow array
        StaticComponents.EnterVariation,
        StaticComponents.DrinkSelection,
        StaticComponents.Intro
    ); 

    const variation = Variations.find(variation => variation.hasOwnProperty(jatos.studySessionData['variation_id']))
    //const variation = Variations[runningID % Variations.length]; // get element of Variations based on runningID
    variationID = Object.keys(variation)[0]; // get e.g. A1, A2 etc. key
    const entries = variation[variationID]; // get content of variation element e.g. A1

    // How many conditions have been performed before scanning
    const keys_1 = ["A1", "B1", "C1", "D1", "E1"];
    const keys_0 = ["A2", "B2", "C2", "D2", "E2"];
    const keys_3 = ["A3", "B3", "C3", "D3", "E3"];
    const keys_2 = ["A4", "B4", "C4", "D4", "E4"];

    if (keys_0.includes(variationID)) { // if no conditions have been performed outside scanner

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

        componentFlow.push(StaticComponents.OutroScanner); // push outro

    } else if (keys_1.includes(variationID)) { // if one condition has been performed outside scanner

        componentFlow.push(`interlude-1`); // push outro

        entries.forEach(function (entry, entryIndex) {
            const condition = Object.keys(entry)[0]; // get condition (key)
            const environment = entry[condition]; // get environment (value)

            Phases.forEach(function (phase) {
                const component = `${condition}-${phase}`; 
                environmentMap[component] = environment; // save environment to use per condition (easier to access later than going into Variations)
                componentFlow.push(component);
            });

            if (entryIndex < (entries.length - 1)) { // after every condition except last
                componentFlow.push(`interlude-${entryIndex + 2}`); // add interlude
            }
        });

        componentFlow.push(StaticComponents.OutroScanner); // push outro

    } else if (keys_2.includes(variationID)) { // if two conditions have been performed outside scanner


        componentFlow.push(`interlude-2`); // push outro

        entries.forEach(function (entry, entryIndex) {
            const condition = Object.keys(entry)[0]; // get condition (key)
            const environment = entry[condition]; // get environment (value)

            Phases.forEach(function (phase) {
                const component = `${condition}-${phase}`; 
                environmentMap[component] = environment; // save environment to use per condition (easier to access later than going into Variations)
                componentFlow.push(component);
            });

            if (entryIndex < (entries.length - 1)) { // after every condition except last
                componentFlow.push(`interlude-${entryIndex + 3}`); // add interlude
            }
        });

        componentFlow.push(StaticComponents.OutroScanner); // push outro

    } else if (keys_3.includes(variationID)) { // if three conditions have been performed outside scanner

        componentFlow.push(`interlude-3`); // push outro

        entries.forEach(function (entry, entryIndex) {
            const condition = Object.keys(entry)[0]; // get condition (key)
            const environment = entry[condition]; // get environment (value)

            Phases.forEach(function (phase) {
                const component = `${condition}-${phase}`; 
                environmentMap[component] = environment; // save environment to use per condition (easier to access later than going into Variations)
                componentFlow.push(component);
            });

            if (entryIndex < (entries.length - 1)) { // after every condition except last
                componentFlow.push(`interlude-${entryIndex + 4}`); // add interlude
            }
        });

        componentFlow.push(StaticComponents.OutroFinal); // push outro
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

// define how many learning trials start in which state
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

// define how many viewing trials start in which state
function defineViewingPhaseStartStates() {
  const elements = [
    "1LeftViewing", "1RightViewing", "2LeftViewing", "2RightViewing", 
    "3LeftViewing", "3RightViewing", "4Viewing", "5Viewing", 
    "6Viewing", "7Viewing", "8Viewing", "9Viewing", "10Viewing"
  ];

  // Step 1: Repeat each element 12 times
  let repeatedElements = [];
  elements.forEach(element => {
    for (let i = 0; i < 12; i++) {
      repeatedElements.push(element);
    }
  });

  // Step 2: Initialize transition map to track used transitions
  let transitions = {};
  elements.forEach(from => {
    transitions[from] = {};
    elements.forEach(to => {
      if (from !== to) {
        transitions[from][to] = 0; // 0 means unused transition
      }
    });
  });

  // Step 3: Recursive function to build the list
  function buildList(currentList, remainingElements) {
    if (remainingElements.length === 0) {
      return currentList; // List is complete
    }

    let lastElement = currentList[currentList.length - 1];

    // Get valid next choices (those with unused transitions and unidentical to last element)
    let choices = remainingElements.filter(next => 
      next !== lastElement && transitions[lastElement][next] === 0
    );

    // Shuffle choices to randomize the selection order
    choices = choices.sort(() => Math.random() - 0.5);

    // Try each choice in randomized order
    for (let nextElement of choices) {
      // Mark transition as used
      transitions[lastElement][nextElement] = 1;

      // Remove nextElement from remaining and add it to current list
      let index = remainingElements.indexOf(nextElement);
      let newRemainingElements = remainingElements.slice();
      newRemainingElements.splice(index, 1);

      // Recursive call with the new list and remaining elements
      let result = buildList([...currentList, nextElement], newRemainingElements);
      if (result) {
        return result; // Solution found
      }

      // Backtrack: unmark the transition if solution not found
      transitions[lastElement][nextElement] = 0;
    }

    return null; // No valid solution found from this path
  }

  // Start with a random initial element
  let startElement = repeatedElements[Math.floor(Math.random() * repeatedElements.length)];
  let initialIndex = repeatedElements.indexOf(startElement);
  let initialRemainingElements = repeatedElements.slice();
  initialRemainingElements.splice(initialIndex, 1);

  // Build the list starting with the chosen initial element
  let randomizedList = buildList([startElement], initialRemainingElements);

  return randomizedList;
}




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

    const image = document.getElementById("image");
    image.removeAttribute("src");
    image.style.opacity = 1;
    setImageFromEnvironment("image", `${state.imageName}`, stateName);

    stateOnset = Date.now();

    drink = jatos.studySessionData["drink"]; // which drink should be used as reward

    // wait for a choice to be made
    doAfter(state.preChoiceTime, function() { // after delay defined per state, do...

        let didMakeChoice = false; // no choice made yet
        let cueOnset = Date.now(); // will be overwritten if response is made
        let responseOnset = null; // will be overwritten if response is made

        // two choice states
        if (state instanceof TwoChoiceState) {

            // forced choice left
            if (state.nextStateLeft != null && state.nextStateRight == null) {

                setImageFromEnvironment("image", `${state.imageName}_highlighted_left`, stateName); // show same image with highlighted options

                enableTwoChoiceInputLeft(function(input, cueOnset, responseOnset, RT) {
                    didMakeChoice = true; // valid choice made
                    setImageFromEnvironment("image", `${state.imageName}_left`, stateName); // set selected image

                    feedbackOnset = Date.now();

                    doAfter(state.afterChoiceTime, function() {
                        configure(state.nextStateLeft, states, trialResults, trialResultHandler); // move to next state's image
                    });
                    
                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT, 'state_onset': stateOnset, 'cue_onset': cueOnset,
                        'response_onset': responseOnset, 'feedback_onset': feedbackOnset}); // log results
                });
            }
            
            // forced choice right
            else if (state.nextStateLeft == null && state.nextStateRight != null) {

                setImageFromEnvironment("image", `${state.imageName}_highlighted_right`, stateName); // show same image with highlighted options

                enableTwoChoiceInputRight(function(input, cueOnset, responseOnset, RT) {
                    didMakeChoice = true; // valid choice made
                    setImageFromEnvironment("image", `${state.imageName}_right`, stateName); // set selected image

                    feedbackOnset = Date.now();

                    doAfter(state.afterChoiceTime, function() {
                        configure(state.nextStateRight, states, trialResults, trialResultHandler); // move to next state's image
                    });
                    
                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT, 'state_onset': stateOnset, 'cue_onset': cueOnset,
                        'response_onset': responseOnset, 'feedback_onset': feedbackOnset}); // log results
                });
            }
            
            // end trial during test phase
            else if (state.nextStateLeft == null && state.nextStateRight == null) {

                setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName); // show same image with highlighted options

                enableTwoChoiceInput(function(input, cueOnset, responseOnset, RT) {
                    didMakeChoice = true; // valid choice made

                    if (input == TwoChoiceInput.Left) {
                        setImageFromEnvironment("image", `${state.imageName}_left`, stateName); // set selected image
                    }
                    else if (input == TwoChoiceInput.Right) {
                        setImageFromEnvironment("image", `${state.imageName}_right`, stateName);
                    }

                    feedbackOnset = Date.now();

                    doAfter(state.afterChoiceTime, function() {
                        fadeOut(image, function() {
                            trialResultHandler(trialResults, true);
                        });
                    });

                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT, 'state_onset': stateOnset, 'cue_onset': cueOnset,
                        'response_onset': responseOnset, 'feedback_onset': feedbackOnset}); // log results
                });

            }

            // free choice
            else {

                setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName); // show same image with highlighted options

                enableTwoChoiceInput(function(input, cueOnset, responseOnset, RT) {
                    didMakeChoice = true; // valid choice made

                    if (input == TwoChoiceInput.Left) {
                        setImageFromEnvironment("image", `${state.imageName}_left`, stateName); // set selected image

                        feedbackOnset = Date.now();

                        doAfter(state.afterChoiceTime, function() {
                            configure(state.nextStateLeft, states, trialResults, trialResultHandler);
                        });
                    }
                    else if (input == TwoChoiceInput.Right) {
                        setImageFromEnvironment("image", `${state.imageName}_right`, stateName);

                        feedbackOnset = Date.now();

                        doAfter(state.afterChoiceTime, function() {
                            configure(state.nextStateRight, states, trialResults, trialResultHandler);
                        });
                    }

                    trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'choice':input, 'RT':RT, 'state_onset': stateOnset, 'cue_onset': cueOnset,
                        'response_onset': responseOnset, 'feedback_onset': feedbackOnset}); // log results

                });
            }   
        }

        // one choice states
        else if (state instanceof OneChoiceState) { 

            setImageFromEnvironment("image", `${state.imageName}_highlighted`, stateName); // show same image with highlighted options

            enableOneChoiceInput(function(cueOnset, responseOnset, RT) {
                didMakeChoice = true; // valid choice made
                setImageFromEnvironment("image", `${state.imageName}_selected`, stateName); // set selected image

                feedbackOnset = Date.now();

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

                trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'RT':RT, 'state_onset': stateOnset, 'cue_onset': cueOnset,
                        'response_onset': responseOnset, 'feedback_onset': feedbackOnset}); // log results

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
                
                feedbackOnset = Date.now();

                doAfter(overlayTime, function() {
                    jatos.removeOverlay();

                    fadeOut(image, function() {
                        trialResultHandler(trialResults, false);
                    });

                });

                trialResults.push({'state':stateName, 'valid_choice':didMakeChoice, 'state_onset': stateOnset, 'cue_onset': cueOnset,
                        'response_onset': responseOnset, 'feedback_onset': feedbackOnset}); // log results

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

    stateOnset = Date.now();

    // initialize timing and selection variables
    let questionOnset = null;
    let responseOnset = null;
    let RT = null;
    let selection = null;
    let didMakeChoice = false;

    doAfter(viewingTime, function() {

        image.style.display = "none";

        if (questionTrial === 1) {
            // define text for question ITIs
            const questionText = [
                    `Wie viele Gläser Alkohol können Sie maximal auf dem Weg erhalten, der der letzten Handlung folgt?
                    <br>
                    ('links außen' - 'rechts außen')`
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

                if (event.key == Keyboard.One) {
                    disableInput(); // disable any further input
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "0";
                    optionLeftLeft.classList.add("quiz_option_selected");
                    optionLeftMiddle.classList.remove("quiz_option_selected");
                    optionRightMiddle.classList.remove("quiz_option_selected");
                    optionRightRight.classList.remove("quiz_option_selected");
                }
                else if (event.key == Keyboard.Two) {
                    disableInput(); // disable any further input
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "1";
                    optionLeftLeft.classList.remove("quiz_option_selected");
                    optionLeftMiddle.classList.add("quiz_option_selected");
                    optionRightMiddle.classList.remove("quiz_option_selected");
                    optionRightRight.classList.remove("quiz_option_selected");
                }
                else if (event.key == Keyboard.Three) {
                    disableInput(); // disable any further input
                    responseOnset = Date.now();
                    RT = responseOnset - questionOnset;
                    didMakeChoice = true;
                    selection = "2";
                    optionLeftLeft.classList.remove("quiz_option_selected");
                    optionLeftMiddle.classList.remove("quiz_option_selected");
                    optionRightMiddle.classList.add("quiz_option_selected");
                    optionRightRight.classList.remove("quiz_option_selected");
                    
                } else if (event.key == Keyboard.Four) {
                    disableInput(); // disable any further input
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
                viewingResults.push({'state':stateName, 'question_trial': questionTrial, 'valid_choice':didMakeChoice, 'selection': selection, 'RT': RT, 
                    'state_onset': stateOnset, 'question_onset': questionOnset, 'response_onset': responseOnset}); // log results
                viewingResultsHandler(viewingResults, true);
            })

        } else {

            console.log(selection);
            viewingResults.push({'state':stateName, 'question_trial': questionTrial, 'valid_choice':didMakeChoice, 'selection': selection, 'RT': RT, 
                'state_onset': stateOnset, 'question_onset': questionOnset, 'response_onset': responseOnset}); // log results
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

        console.log(viewingStateIndex)
        console.log(viewingITI[viewingStateIndex-2])
        doAfter(viewingITI[viewingStateIndex-2], function() {
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
    Space: "",
    Enter: "Enter",
    Trigger: "5",
    One: "1",
    Two: "2",
    Three: "3",
    Four: "4"
};

const TwoChoiceInput = { // left and right choice, independent of which keys are used
    Left: "left",
    Right: "right"
};

function enableOneChoiceInput(callback) { // allowed keys for 1-choice states
    
    const cueOnset = Date.now(); // log time at cue onset

    document.onkeydown = function(event) {
        console.log(event.key);
        if (event.key == Keyboard.Two) { // change input key here
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(cueOnset, responseOnset, RT); // call what I put in as callback function
        }
        else {
            jatos.showOverlay({
                text: "Nur gelb (links innen) gültig!",
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
        if (event.key == Keyboard.Three) { // change input key here
            console.log(event.key);
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Left, cueOnset, responseOnset, RT); // execute function defined as callback function with input TwoChoioceInput.Left
        }
        else if (event.key == Keyboard.Four) { // change input key here
            console.log(event.key);
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Right, cueOnset, responseOnset, RT); // execute function defined as callback function with input TwoChoioceInput.Right
        }
        else {
            jatos.showOverlay({
                text: "Nur grün (rechts innen) oder rot (rechts außen) gültig!",
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
        console.log(event.key);
        if (event.key == Keyboard.Three) { // change input key here
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Left, cueOnset, responseOnset, RT); // execute function defined as callback function with input TwoChoioceInput.Left
        }
        else {
            jatos.showOverlay({
                text: "Nur grün (rechts innen) gültig!",
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
        console.log(event.key);
        if (event.key == Keyboard.Four) { // change input key here
            const responseOnset = Date.now();
            const RT = responseOnset - cueOnset;
            disableInput(); // disable any further input
            jatos.removeOverlay(); // remove wrong key overlay if present
            callback(TwoChoiceInput.Right, cueOnset, responseOnset, RT); // execute function defined as callback function with input TwoChoioceInput.Right
        }
        else {
            jatos.showOverlay({
                text: "Nur rot (rechts außen) gültig!",
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
 * Scanner trigger logging
 */

function waitForInitialTrigger(triggerIndex, callback) { // allowed keys for 1-choice states

    document.onkeydown = function(event) {
        if (event.key == Keyboard.Trigger) { // change input key here
            triggerIndex = triggerIndex + 1;
            if (triggerIndex < 5) {
                waitForInitialTrigger(triggerIndex, callback)
            } else {
                const triggerOnset = Date.now(); 
                disableInput(); // disable any further input
                callback(triggerOnset); // call what I put in as callback function
            }
        }
    };
}

function waitForTrigger(callback) { // allowed keys for 1-choice states

    document.onkeydown = function(event) {
        if (event.key == Keyboard.Trigger) { // change input key here
            const triggerOnset = Date.now(); 
            disableInput(); // disable any further input
            callback(triggerOnset); // call what I put in as callback function
        }
    };
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

function shuffleNumbers(...numbers) { // returns randomly shuffled elements
    let arrayCopy = [...numbers];
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
    Intro: "intro",
    DrinkSelection: "drink-selection",
    OutroScanner: "outro-scanner",
    OutroFinal: "outro-final"
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
    "test",
    "viewing1",
    "viewing2"
];


/*
 * Variations
 */
const Variations = [
    
    {
        "A1": [
            {"transition1": "brauhaus"},
            {"transition2": "fancy_green"}
        ]
    },
    {
        "A2": [
            {"transition1": "alternative"},
            {"transition2": "brauhaus"}
        ]
    },
    {
        "A3": [
            {"transition1": "hip_purple"},
            {"transition2": "sports_bar"}
            ]
    },
    {
        "A4": [
            {"transition1": "fancy_green"},
            {"transition2": "hip_purple"}
        ]
    },
    {
        "B1": [
            {"transition1": "fancy_green"},
            {"transition2": "hip_purple"}
        ]
    },
    {
        "B2": [
            {"transition1": "brauhaus"},
            {"transition2": "hip_purple"}
        ]
    },
    {
        "B3": [
            {"transition1": "alternative"},
            {"transition2": "fancy_green"}
        ]
    },
    {
        "B4": [
            {"transition1": "sports_bar"},
            {"transition2": "alternative"},
        ]
    },
    {
        "C1": [
            {"transition1": "hip_purple"},
            {"transition2": "sports_bar"}
        ]
    },
    {
        "C2": [
            {"transition1": "fancy_green"},
            {"transition2": "sports_bar"}
        ]
    },
    {
        "C3": [
            {"transition1": "brauhaus"},
            {"transition2": "hip_purple"}
        ]
    },
    {
        "C4": [
            {"transition1": "alternative"},
            {"transition2": "brauhaus"}
        ]
    },
    {
        "D1": [
            {"transition1": "sports_bar"},
            {"transition2": "alternative"}
        ]
    },
    {
        "D2": [
            {"transition1": "hip_purple"},
            {"transition2": "sports_bar"}
    ]
    },
    {
        "D3": [
            {"transition1": "fancy_green"},
            {"transition2": "brauhaus"}
        ]
    },
    {
        "D4": [
            {"transition1": "alternative"},
            {"transition2": "fancy_green"}
        ]
    },
    {
        "E1": [
            {"transition1": "alternative"},
            {"transition2": "brauhaus"}
        ]
    },
    {
        "E2": [
            {"transition1": "sports_bar"},
            {"transition2": "alternative"}
        ]
    },
    {
        "E3": [
            {"transition1": "hip_purple"},
            {"transition2": "brauhaus"}
        ]
    },
    {
        "E4": [
            {"transition1": "fancy_green"},
            {"transition2": "brauhaus"}
        ]
}
];





// callback is a function that is passed into another function so that it can be executed after waiting for asynchronous event