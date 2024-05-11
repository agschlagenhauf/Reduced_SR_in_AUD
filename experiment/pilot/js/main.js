/*
 * main.js
 */

var participantID = null;
var environmentMap = {}; // mapping btw condition & environment
var componentFlow = []; // list of component titles (reward learning etc.)
var componentIndex = 0; // current component index

/*
 * Component Flow
 */
function prepareComponentFlow(jatos) { // prepare list of what we should show
    participantID = 25; // get from JATOS

    componentFlow.push(StaticComponents.Intro); // add StaticComponents to componentFlow array

    var variation = Variations[participantID % Variations.length]; // get element of Variations based on participantID
    var variationID = Object.keys(variation)[0]; // get e.g. A1, A2 etc. key
    var entries = variation[variationID]; // get content of variation element e.g. A1

    for (let i = 0; i < entries.length; i++) { // for loop from 0 to length(entries) in steps of 1
        var entry = entries[i];
        var condition = Object.keys(entry)[0]; // get condition (key)
        var environment = entry[condition]; // get environment (entry)

        for (phaseIndex in Phases) { // add phase to respective condition in environment
            var component = `${condition}-${Phases[phaseIndex]}`; 
            environmentMap[component] = environment; // save environment to use per condition (easier to access later than going into Variations)
            componentFlow.push(component);
        }

        if (i < (entries.length - 1)) { // after every condition except last
            componentFlow.push(`interlude-${i + 1}`) // add interlude
        }
    }
    
    componentFlow.push(StaticComponents.Outro); // push outro

    console.log(componentFlow);

    jatos.studySessionData = { // save session data to pass to other components
        "participant_id": participantID,
        "variation_id": variationID,
        "environment_map": environmentMap,
        "component_flow": componentFlow,
        "component_index": componentIndex
    };
}

function startComponentFlow(jatos) { // start flow
    showNextComponent(jatos);
    // what to log on start?
}

function loadStudySessionData(jatos) {
    participantID = jatos.studySessionData["participant_id"];
    environmentMap = jatos.studySessionData["environment_map"];
    componentFlow = jatos.studySessionData["component_flow"];
    componentIndex = jatos.studySessionData["component_index"];
}

function showNextComponent(jatos) { // move through elements of componentFlow list
    componentIndex += 1;
    jatos.studySessionData["component_index"] = componentIndex;

    var componentTitle = componentFlow[componentIndex]; // get component title
    jatos.startComponentByTitle(componentTitle); // tell JATOS to start component
}

function endComponentFlow(jatos) { // end flow (called in outro)
    jatos.endStudy();
    // redirect to RedCap
}

function handleComponentInput(jatos, event) { 

    switch (event.key) {
        case Keyboard.SpaceBar:
            break;
        case Keyboard.LeftArrow:
            break;
        case Keyboard.RightArrow:
            showNextComponent(jatos);
            break;
        default:
            break;
    }
}

/*
 * Phases
 */
const Phases = [
    "learning",
    "relearning",
    "test"
];

/*
 * Static Components
 */
const StaticComponents = {
    Intro: "intro",
    Outro: "outro"
};

/*
 * Variations
 */
const Variations = [
    {A1: [
        {"reward":      "light_blue"},
        {"transition":  "messy_green"},
        {"policy":      "orange_tile"},
        {"goal-state":  "red_brown"},
        {"control":     "white_modern"}
    ]},
    {A2: [
        {"reward":      "messy_green"},
        {"transition":  "orange_tile"},
        {"policy":      "red_brown"},
        {"goal-state":  "white_modern"},
        {"control":     "light_blue"}
    ]},
    {A3: [
        {"reward":      "orange_tile"},
        {"transition":  "red_brown"},
        {"policy":      "white_modern"},
        {"goal-state":  "light_blue"},
        {"control":     "messy_green"}
    ]},
    {A4: [
        {"reward":      "red_brown"},
        {"transition":  "white_modern"},
        {"policy":      "light_blue"},
        {"goal-state":  "messy_green"},
        {"control":     "orange_tile"}
    ]},
    {A5: [
        {"reward":      "white_modern"},
        {"transition":  "light_blue"},
        {"policy":      "messy_green"},
        {"goal-state":  "orange_tile"},
        {"control":     "red_brown"}
    ]},
    {B1: [
        {"transition":  "light_blue"},
        {"policy":      "messy_green"},
        {"goal-state":  "orange_tile"},
        {"control":     "red_brown"},
        {"reward":      "white_modern"}
    ]},
    {B2: [
        {"transition":  "messy_green"},
        {"policy":      "orange_tile"},
        {"goal-state":  "red_brown"},
        {"control":     "white_modern"},
        {"reward":      "light_blue"}
    ]},
    {B3: [
        {"transition":  "orange_tile"},
        {"policy":      "red_brown"},
        {"goal-state":  "white_modern"},
        {"control":     "light_blue"},
        {"reward":      "messy_green"}
    ]},
    {B4: [
        {"transition":  "red_brown"},
        {"policy":      "white_modern"},
        {"goal-state":  "light_blue"},
        {"control":     "messy_green"},
        {"reward":      "orange_tile"}
    ]},
    {B5: [
        {"transition":  "white_modern"},
        {"policy":      "light_blue"},
        {"goal-state":  "messy_green"},
        {"control":     "orange_tile"},
        {"reward":      "red_brown"}
    ]},
    {C1: [
        {"policy":      "light_blue"},
        {"goal-state":  "messy_green"},
        {"control":     "orange_tile"},
        {"reward":      "red_brown"},
        {"transition":  "white_modern"}
    ]},
    {C2: [
        {"policy":      "messy_green"},
        {"goal-state":  "orange_tile"},
        {"control":     "red_brown"},
        {"reward":      "white_modern"},
        {"transition":  "light_blue"}
    ]},
    {C3: [
        {"policy":      "orange_tile"},
        {"goal-state":  "red_brown"},
        {"control":     "white_modern"},
        {"reward":      "light_blue"},
        {"transition":  "messy_green"}
    ]},
    {C4: [
        {"policy":      "red_brown"},
        {"goal-state":  "white_modern"},
        {"control":     "light_blue"},
        {"reward":      "messy_green"},
        {"transition":  "orange_tile"}
    ]},
    {C5: [
        {"policy":      "white_modern"},
        {"goal-state":  "light_blue"},
        {"control":     "messy_green"},
        {"reward":      "orange_tile"},
        {"transition":  "red_brown"}
    ]},
    {D1: [
        {"goal-state":  "light_blue"},
        {"control":     "messy_green"},
        {"reward":      "orange_tile"},
        {"transition":  "red_brown"},
        {"policy":      "white_modern"}
    ]},
    {D2: [
        {"goal-state":  "messy_green"},
        {"control":     "orange_tile"},
        {"reward":      "red_brown"},
        {"transition":  "white_modern"},
        {"policy":      "light_blue"}
    ]},
    {D3: [
        {"goal-state":  "orange_tile"},
        {"control":     "red_brown"},
        {"reward":      "white_modern"},
        {"transition":  "light_blue"},
        {"policy":      "messy_green"}
    ]},
    {D4: [
        {"goal-state":  "red_brown"},
        {"control":     "white_modern"},
        {"reward":      "light_blue"},
        {"transition":  "messy_green"},
        {"policy":      "orange_tile"}
    ]},
    {D5: [
        {"goal-state":  "white_modern"},
        {"control":     "light_blue"},
        {"reward":      "messy_green"},
        {"transition":  "orange_tile"},
        {"policy":      "red_brown"}
    ]},
    {E1: [
        {"control":     "light_blue"},
        {"reward":      "messy_green"},
        {"transition":  "orange_tile"},
        {"policy":      "red_brown"},
        {"goal-state":  "white_modern"}
    ]},
    {E2: [
        {"control":     "messy_green"},
        {"reward":      "orange_tile"},
        {"transition":  "red_brown"},
        {"policy":      "white_modern"},
        {"goal-state":  "light_blue"}
    ]},
    {E3: [
        {"control":     "orange_tile"},
        {"reward":      "red_brown"},
        {"transition":  "white_modern"},
        {"policy":      "light_blue"},
        {"goal-state":  "messy_green"}
    ]},
    {E4: [
        {"control":     "red_brown"},
        {"reward":      "white_modern"},
        {"transition":  "light_blue"},
        {"policy":      "messy_green"},
        {"goal-state":  "orange_tile"}
    ]},
    {E5: [
        {"control":     "white_modern"},
        {"reward":      "light_blue"},
        {"transition":  "messy_green"},
        {"policy":      "orange_tile"},
        {"goal-state":  "red_brown"}
    ]}
];

/*
 * Utilities
 */
const Keyboard = { // allows to use Keyboard.F etc.
    F: "f",
    J: "j",
    LeftArrow: "ArrowLeft",
    RightArrow: "ArrowRight"
};
