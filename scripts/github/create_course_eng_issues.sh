#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# German Article Trainer
# Create COURSE-F2, ENG-M0, ENG-M1 and ST7789 experiment issues
#
# Requirements:
#   - gh installed
#   - gh authenticated
#   - run inside the repository
#   - milestones and labels already created
# ============================================================

COURSE_MILESTONE="COURSE-F2 — State of the Art"
ENG_M0_MILESTONE="ENG-M0 — Platform Baseline"
ENG_M1_MILESTONE="ENG-M1 — Minimal Trainer"

COURSE_PARENT_TITLE="Complete COURSE-F2 state of the art"
ENG_M0_PARENT_TITLE="Establish engineering platform baseline"
ENG_M1_PARENT_TITLE="Implement minimal trainer MVP"

echo "============================================================"
echo " German Article Trainer"
echo " GitHub issue initialization"
echo "============================================================"
echo

# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) is not installed."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI is not authenticated."
    echo "Run:"
    echo "  gh auth login"
    exit 1
fi

REPO="$(gh repo view --json nameWithOwner -q '.nameWithOwner')"

if [[ -z "$REPO" ]]; then
    echo "ERROR: Could not detect repository."
    exit 1
fi

echo "Repository: $REPO"
echo

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

issue_number_by_title() {
    local title="$1"

    gh issue list \
        --repo "$REPO" \
        --state all \
        --limit 500 \
        --json number,title \
        --jq ".[] | select(.title == \"$title\") | .number" \
        | head -n 1
}

issue_exists() {
    local title="$1"

    [[ -n "$(issue_number_by_title "$title")" ]]
}

milestone_exists() {
    local milestone="$1"

    gh api \
        "repos/$REPO/milestones?state=all&per_page=100" \
        --jq '.[].title' \
        | grep -Fxq "$milestone"
}

label_exists() {
    local label="$1"

    gh label list \
        --repo "$REPO" \
        --limit 200 \
        --json name \
        --jq '.[].name' \
        | grep -Fxq "$label"
}

require_milestone() {
    local milestone="$1"

    if ! milestone_exists "$milestone"; then
        echo "ERROR: Missing milestone:"
        echo "  $milestone"
        exit 1
    fi
}

require_label() {
    local label="$1"

    if ! label_exists "$label"; then
        echo "ERROR: Missing label:"
        echo "  $label"
        exit 1
    fi
}

create_parent_issue() {
    local title="$1"
    local milestone="$2"
    local body="$3"
    shift 3
    local labels=("$@")

    local existing
    existing="$(issue_number_by_title "$title")"

    if [[ -n "$existing" ]]; then
        echo "FOUND parent #$existing: $title"
        echo "$existing"
        return
    fi

    local cmd=(
        gh issue create
        --repo "$REPO"
        --title "$title"
        --body "$body"
        --milestone "$milestone"
    )

    for label in "${labels[@]}"; do
        cmd+=(--label "$label")
    done

    local url
    url="$("${cmd[@]}")"

    local number="${url##*/}"

    echo "CREATED parent #$number: $title"
    echo "$number"
}

create_subissue() {
    local parent="$1"
    local title="$2"
    local milestone="$3"
    local effort="$4"
    local objective="$5"
    local tasks="$6"
    local acceptance="$7"
    local validation="$8"
    shift 8
    local labels=("$@")

    echo
    echo "------------------------------------------------------------"
    echo "$title"

    local existing
    existing="$(issue_number_by_title "$title")"

    if [[ -n "$existing" ]]; then
        echo "SKIP: issue already exists as #$existing"
        return
    fi

    local body
    body="$(cat <<EOF
## Objective

$objective

## Tasks

$tasks

## Acceptance criteria

$acceptance

## Validation

$validation

## Estimated effort

$effort
EOF
)"

    local cmd=(
        gh issue create
        --repo "$REPO"
        --title "$title"
        --body "$body"
        --milestone "$milestone"
        --parent "$parent"
    )

    for label in "${labels[@]}"; do
        cmd+=(--label "$label")
    done

    local url
    url="$("${cmd[@]}")"

    echo "CREATED: $url"
}

create_standalone_issue() {
    local title="$1"
    local effort="$2"
    local objective="$3"
    local tasks="$4"
    local acceptance="$5"
    local validation="$6"
    shift 6
    local labels=("$@")

    echo
    echo "------------------------------------------------------------"
    echo "$title"

    local existing
    existing="$(issue_number_by_title "$title")"

    if [[ -n "$existing" ]]; then
        echo "SKIP: issue already exists as #$existing"
        return
    fi

    local body
    body="$(cat <<EOF
## Objective

$objective

## Tasks

$tasks

## Acceptance criteria

$acceptance

## Validation

$validation

## Estimated effort

$effort
EOF
)"

    local cmd=(
        gh issue create
        --repo "$REPO"
        --title "$title"
        --body "$body"
    )

    for label in "${labels[@]}"; do
        cmd+=(--label "$label")
    done

    local url
    url="$("${cmd[@]}")"

    echo "CREATED: $url"
}

# ------------------------------------------------------------
# Validate milestones
# ------------------------------------------------------------

require_milestone "$COURSE_MILESTONE"
require_milestone "$ENG_M0_MILESTONE"
require_milestone "$ENG_M1_MILESTONE"

# ------------------------------------------------------------
# Validate labels
# ------------------------------------------------------------

for label in \
    "type:feature" \
    "type:test" \
    "type:documentation" \
    "type:hardware" \
    "type:research" \
    "area:trainer" \
    "area:lexical" \
    "area:hmi" \
    "area:hardware" \
    "priority:high" \
    "priority:medium" \
    "priority:low"
do
    require_label "$label"
done

# ============================================================
# COURSE-F2
# ============================================================

COURSE_PARENT_BODY="$(cat <<'EOF'
## Objective

Complete Phase 2 of course 203059 through a structured state-of-the-art review, identification of gaps, and development of the conceptual and theoretical framework.

## Scope

This issue groups the literature-review and theoretical-foundation work for COURSE-F2.

## Completion criteria

- Literature search methodology documented
- Minimum required scientific references selected
- Literature review matrix completed
- State of the art analyzed
- Research and technological gaps identified
- Conceptual and theoretical framework developed
- Phase 1 consistency reviewed and updated
EOF
)"

COURSE_PARENT="$(
    create_parent_issue \
        "$COURSE_PARENT_TITLE" \
        "$COURSE_MILESTONE" \
        "$COURSE_PARENT_BODY" \
        "type:research" \
        "type:documentation" \
        "priority:high" \
    | tail -n 1
)"

create_subissue \
"$COURSE_PARENT" \
"Define literature search strategy" \
"$COURSE_MILESTONE" \
"2 h" \
"Define a reproducible search strategy for the academic state-of-the-art review." \
"- [ ] Define research topics
- [ ] Define search strings
- [ ] Define academic databases
- [ ] Define inclusion criteria
- [ ] Define exclusion criteria
- [ ] Define publication period
- [ ] Define quality criteria
- [ ] Document search methodology" \
"- Search methodology is documented
- Search strings are reproducible
- Inclusion and exclusion criteria are explicit
- Strategy supports selection of the required scientific references" \
"Review the documented literature-search methodology." \
"type:research" \
"priority:high"

create_subissue \
"$COURSE_PARENT" \
"Select minimum 15 scientific references" \
"$COURSE_MILESTONE" \
"4 h" \
"Identify and select at least 15 high-quality scientific sources relevant to the linguistic and technological dimensions of the project." \
"- [ ] Execute defined search strategy
- [ ] Review titles and abstracts
- [ ] Apply inclusion and exclusion criteria
- [ ] Select at least 15 relevant sources
- [ ] Record bibliographic metadata
- [ ] Classify references by topic
- [ ] Store DOI or stable source links where applicable" \
"- At least 15 suitable scientific references are selected
- References satisfy the defined criteria
- Sources cover both linguistic and technological aspects
- Bibliographic information is reproducible" \
"Verify selected references against the documented search criteria." \
"type:research" \
"priority:high"

create_subissue \
"$COURSE_PARENT" \
"Build literature review matrix" \
"$COURSE_MILESTONE" \
"4 h" \
"Build the literature review matrix required to systematically compare the selected scientific references." \
"- [ ] Define matrix fields
- [ ] Record publication metadata
- [ ] Record research objective
- [ ] Record methodology
- [ ] Record relevant results
- [ ] Record limitations
- [ ] Record contribution to this project
- [ ] Complete matrix for selected references" \
"- Matrix contains all selected references
- Relevant methodological and result information is recorded
- Contributions and limitations are identifiable
- Matrix supports later state-of-the-art analysis" \
"Review matrix completeness and consistency against selected references." \
"type:research" \
"type:documentation" \
"priority:high"

create_subissue \
"$COURSE_PARENT" \
"Analyze state of the art" \
"$COURSE_MILESTONE" \
"5 h" \
"Develop a critical synthesis of previous work relevant to grammatical-gender learning, embedded training systems, HMI, and supporting language technologies." \
"- [ ] Group references by thematic area
- [ ] Compare approaches
- [ ] Identify common methods
- [ ] Identify relevant technological trends
- [ ] Analyze strengths and limitations
- [ ] Relate previous work to the proposed system
- [ ] Draft state-of-the-art section" \
"- Analysis is thematic rather than a simple list of papers
- Relationships among previous approaches are explicit
- Technological and educational perspectives are represented
- Analysis supports the project problem and proposed contribution" \
"Review the state-of-the-art section against the literature matrix." \
"type:research" \
"type:documentation" \
"priority:high"

create_subissue \
"$COURSE_PARENT" \
"Identify research and technological gaps" \
"$COURSE_MILESTONE" \
"3 h" \
"Identify gaps in previous work that justify the proposed embedded-system approach." \
"- [ ] Identify limitations of existing approaches
- [ ] Identify unresolved linguistic-training needs
- [ ] Identify HMI or embedded-system opportunities
- [ ] Distinguish research gaps from implementation opportunities
- [ ] Relate gaps to project objectives
- [ ] Document justified project contribution" \
"- Gaps are supported by reviewed literature
- Gaps are not based solely on assumptions
- Identified gaps connect directly with the proposed project
- Technological-development opportunity is explicit" \
"Cross-check each stated gap against the literature review." \
"type:research" \
"priority:high"

create_subissue \
"$COURSE_PARENT" \
"Develop conceptual and theoretical framework" \
"$COURSE_MILESTONE" \
"5 h" \
"Develop the conceptual and theoretical framework supporting the linguistic and technological foundations of the project." \
"- [ ] Define German grammatical gender concepts
- [ ] Define noun-article association
- [ ] Describe relevant L1-L2 transfer concepts
- [ ] Define embedded-system concepts
- [ ] Define relevant HMI concepts
- [ ] Define NLP role
- [ ] Define generative AI role and limitations
- [ ] Integrate appropriate references" \
"- Framework uses consistent terminology
- Linguistic and technological foundations are both covered
- Relevant claims have academic support
- Framework aligns with the project objectives and scope" \
"Review framework coherence and cited support." \
"type:research" \
"type:documentation" \
"priority:high"

create_subissue \
"$COURSE_PARENT" \
"Update Phase 1 consistency" \
"$COURSE_MILESTONE" \
"2 h" \
"Review and update Phase 1 so that the problem, justification, research question, objectives, and scope remain coherent after the literature review." \
"- [ ] Review problem statement
- [ ] Review justification
- [ ] Review research question
- [ ] Review general objective
- [ ] Review specific objectives
- [ ] Review scope
- [ ] Apply only evidence-supported corrections
- [ ] Verify terminology consistency" \
"- Phase 1 sections are internally coherent
- Literature-review findings are reflected where relevant
- Core project purpose has not drifted
- Objectives remain feasible and measurable" \
"Perform a consistency review across all updated Phase 1 sections." \
"type:documentation" \
"type:research" \
"priority:high"

# ============================================================
# ENG-M0
# ============================================================

ENG_M0_PARENT_BODY="$(cat <<'EOF'
## Objective

Establish a documented and reproducible engineering baseline for software development and hardware integration.

## Completion criteria

- Reference platform documented
- Repository structure initialized
- Python development environment reproducible
- pytest and CI operational
- Initial requirements baseline documented
EOF
)"

ENG_M0_PARENT="$(
    create_parent_issue \
        "$ENG_M0_PARENT_TITLE" \
        "$ENG_M0_MILESTONE" \
        "$ENG_M0_PARENT_BODY" \
        "type:documentation" \
        "area:hardware" \
        "priority:high" \
    | tail -n 1
)"

create_subissue \
"$ENG_M0_PARENT" \
"Document reference platform baseline" \
"$ENG_M0_MILESTONE" \
"1 h" \
"Document the initial integration platform and current hardware-validation status." \
"- [ ] Record processing platform
- [ ] Record installed memory
- [ ] Record operating system
- [ ] Record kernel version
- [ ] Record Python and Git versions
- [ ] Record storage availability
- [ ] Record temperature
- [ ] Record throttling status
- [ ] Record display operation
- [ ] Record touch-input operation" \
"- Platform data is stored in results/platform/
- Display and touch status are recorded
- Temperature and throttling are recorded
- Baseline is reproducible from the documentation" \
"Review results/platform/p0-validation.md." \
"type:documentation" \
"area:hardware" \
"priority:high"

create_subissue \
"$ENG_M0_PARENT" \
"Initialize repository structure" \
"$ENG_M0_MILESTONE" \
"1 h" \
"Create the initial repository structure for academic, research, software, hardware, experimental, and validation work." \
"- [ ] Create source directories
- [ ] Create test directories
- [ ] Create academic-document directories
- [ ] Create research directories
- [ ] Create hardware directories
- [ ] Create experiment directories
- [ ] Create validation directories
- [ ] Add initial README
- [ ] Add .gitignore" \
"- Required project areas exist in the repository
- Structure is committed to main
- Repository can be cloned cleanly
- Temporary and local-only files are excluded appropriately" \
"Inspect repository tree from a clean clone." \
"type:documentation" \
"priority:high"

create_subissue \
"$ENG_M0_PARENT" \
"Configure Python development environment" \
"$ENG_M0_MILESTONE" \
"1 h" \
"Establish a reproducible Python development environment in WSL." \
"- [ ] Create local virtual environment
- [ ] Define development dependencies
- [ ] Add requirements-dev.txt
- [ ] Install pytest
- [ ] Verify Python execution
- [ ] Document environment setup" \
"- Virtual environment can be recreated
- Development dependencies install successfully
- pytest executes
- Environment setup is documented" \
"Recreate the environment and run pytest." \
"type:feature" \
"priority:high"

create_subissue \
"$ENG_M0_PARENT" \
"Configure pytest and CI workflow" \
"$ENG_M0_MILESTONE" \
"2 h" \
"Establish automated software testing locally and in GitHub Actions." \
"- [ ] Configure pytest
- [ ] Add an initial unit test
- [ ] Create GitHub Actions workflow
- [ ] Run tests on pull requests
- [ ] Run tests on pushes to main
- [ ] Verify successful workflow execution" \
"- pytest passes locally
- At least one automated test exists
- GitHub Actions executes automatically
- CI completes successfully" \
"Verify local pytest and a successful GitHub Actions run." \
"type:test" \
"priority:high"

create_subissue \
"$ENG_M0_PARENT" \
"Create initial requirements baseline" \
"$ENG_M0_MILESTONE" \
"3 h" \
"Create the first technology-independent system requirements baseline." \
"- [ ] Define functional requirements
- [ ] Define data requirements
- [ ] Define interface requirements
- [ ] Define performance requirements
- [ ] Define availability requirements
- [ ] Assign unique requirement identifiers
- [ ] Create initial traceability structure
- [ ] Avoid unnecessary implementation-specific constraints" \
"- Requirements are documented
- Each requirement has a unique identifier
- Requirements are testable where practical
- Initial traceability structure exists
- Core requirements remain platform-independent" \
"Review docs/requirements/system-requirements.md and traceability.md." \
"type:documentation" \
"priority:high"

# ============================================================
# ENG-M1
# ============================================================

ENG_M1_PARENT_BODY="$(cat <<'EOF'
## Objective

Implement the first minimal functional trainer.

## MVP

noun
→ select der/die/das
→ validate answer
→ provide feedback
→ continue with next noun

## Completion criteria

- Minimal requirements defined
- Lexical data can be loaded
- Exercise selection works
- Answer validation works
- Minimal 5-inch HMI works
- Unit tests cover trainer logic
- MVP runs successfully on the reference platform
EOF
)"

ENG_M1_PARENT="$(
    create_parent_issue \
        "$ENG_M1_PARENT_TITLE" \
        "$ENG_M1_MILESTONE" \
        "$ENG_M1_PARENT_BODY" \
        "type:feature" \
        "area:trainer" \
        "priority:high" \
    | tail -n 1
)"

create_subissue \
"$ENG_M1_PARENT" \
"Define minimal trainer requirements" \
"$ENG_M1_MILESTONE" \
"2 h" \
"Define the minimum functional requirements for the first executable trainer baseline." \
"- [ ] Define vocabulary input requirement
- [ ] Define noun presentation requirement
- [ ] Define der/die/das answer input
- [ ] Define answer-validation behavior
- [ ] Define feedback behavior
- [ ] Define next-exercise behavior
- [ ] Define minimal session behavior
- [ ] Map requirements to testable acceptance criteria" \
"- MVP behavior is explicitly defined
- Requirements remain independent of HMI implementation where practical
- Each critical trainer behavior can be tested
- Scope excludes nonessential advanced functionality" \
"Review MVP requirements against the parent issue definition." \
"type:documentation" \
"area:trainer" \
"priority:high"

create_subissue \
"$ENG_M1_PARENT" \
"Implement lexical data loader" \
"$ENG_M1_MILESTONE" \
"3 h" \
"Implement a component that loads validated lexical entries from a structured local dataset." \
"- [ ] Define lexical record structure
- [ ] Create initial vocabulary dataset
- [ ] Implement loader
- [ ] Validate required fields
- [ ] Handle malformed records
- [ ] Add loader tests" \
"- Valid lexical dataset loads successfully
- Missing or invalid required fields are detected
- Trainer logic is not coupled directly to CSV parsing
- Unit tests cover expected and invalid input" \
"Run lexical-loader unit tests." \
"type:feature" \
"area:lexical" \
"priority:high"

create_subissue \
"$ENG_M1_PARENT" \
"Implement exercise selection" \
"$ENG_M1_MILESTONE" \
"2 h" \
"Implement initial exercise-selection logic for choosing nouns from the loaded lexical dataset." \
"- [ ] Define exercise object
- [ ] Implement noun selection
- [ ] Avoid invalid lexical records
- [ ] Support repeated exercise generation
- [ ] Keep selection logic independent of HMI
- [ ] Add unit tests" \
"- Valid exercises can be generated from loaded vocabulary
- Exercise selection is deterministic/testable where required
- UI does not contain exercise-selection logic
- Unit tests pass" \
"Run exercise-selection tests." \
"type:feature" \
"area:trainer" \
"area:lexical" \
"priority:high"

create_subissue \
"$ENG_M1_PARENT" \
"Implement answer validation" \
"$ENG_M1_MILESTONE" \
"2 h" \
"Implement deterministic validation of der, die, and das answers against validated lexical data." \
"- [ ] Define accepted article values
- [ ] Implement answer comparison
- [ ] Return correct/incorrect result
- [ ] Return expected article when incorrect
- [ ] Reject invalid input
- [ ] Add unit tests" \
"- Correct article is accepted
- Incorrect article is rejected
- Expected answer can be reported
- Invalid inputs are handled safely
- Validation does not depend on generative AI" \
"Run answer-validation unit tests." \
"type:feature" \
"area:trainer" \
"area:lexical" \
"priority:high"

create_subissue \
"$ENG_M1_PARENT" \
"Implement minimal 5-inch HMI" \
"$ENG_M1_MILESTONE" \
"4 h" \
"Implement the first minimal local HMI for the main integration display." \
"- [ ] Display current noun
- [ ] Provide der button
- [ ] Provide die button
- [ ] Provide das button
- [ ] Show correct feedback
- [ ] Show incorrect feedback
- [ ] Advance to next exercise
- [ ] Support current display orientation or document required configuration" \
"- User can complete the full MVP interaction locally
- HMI delegates answer validation to trainer logic
- Feedback is visible
- Interaction can proceed repeatedly without restarting the application" \
"Run the MVP manually on the reference display." \
"type:feature" \
"area:hmi" \
"priority:high"

create_subissue \
"$ENG_M1_PARENT" \
"Add trainer unit tests" \
"$ENG_M1_MILESTONE" \
"3 h" \
"Create unit tests covering the core trainer behavior independently from the hardware UI." \
"- [ ] Test lexical-entry handling
- [ ] Test exercise generation
- [ ] Test correct answers
- [ ] Test incorrect answers
- [ ] Test invalid inputs
- [ ] Test multiple sequential exercises
- [ ] Verify tests in CI" \
"- Core trainer functionality is covered by automated tests
- Tests do not require Raspberry Pi hardware
- Test suite passes locally
- Test suite passes in GitHub Actions" \
"Run python -m pytest locally and verify CI." \
"type:test" \
"area:trainer" \
"priority:high"

create_subissue \
"$ENG_M1_PARENT" \
"Deploy and validate M1 on Raspberry Pi 4" \
"$ENG_M1_MILESTONE" \
"3 h" \
"Deploy the minimal trainer baseline to the reference integration platform and validate complete operation." \
"- [ ] Clone or update repository on target
- [ ] Create target Python environment
- [ ] Install application dependencies
- [ ] Run automated tests where applicable
- [ ] Launch trainer
- [ ] Verify display interaction
- [ ] Execute repeated training cycles
- [ ] Record defects
- [ ] Record validation results" \
"- Application starts successfully on target
- Complete noun/article/feedback cycle works
- No blocking errors occur during the validation session
- Validation evidence is stored in results/
- Any defects are recorded as GitHub issues" \
"Perform target integration test and document results." \
"type:test" \
"type:hardware" \
"area:trainer" \
"area:hardware" \
"priority:high"

# ============================================================
# ST7789 EXPERIMENT
# ============================================================

create_standalone_issue \
"Prototype compact HMI on ST7789 display" \
"3 h" \
"Evaluate the 76x284 ST7789 display as a possible compact HMI for a future reduced-size system variant." \
"- [ ] Identify exact module pinout
- [ ] Verify electrical interface
- [ ] Verify SPI communication
- [ ] Display solid-color test
- [ ] Verify resolution
- [ ] Verify landscape rotation
- [ ] Determine required display offsets
- [ ] Display a sample German noun
- [ ] Render answer/feedback states
- [ ] Evaluate readability
- [ ] Record technical limitations
- [ ] Store experimental code under experiments/hmi/st7789/" \
"- Display can be controlled reliably
- 284x76 landscape layout works
- Main noun and feedback states are readable
- Required offsets/rotation are documented
- Experimental source code is committed
- Results are documented without making the display a mandatory system requirement" \
"Run the experiment on physical hardware and record observations." \
"type:hardware" \
"area:hmi" \
"priority:low"

# ============================================================
# Summary
# ============================================================

echo
echo "============================================================"
echo " Issue initialization complete"
echo "============================================================"
echo

echo "COURSE-F2:"
gh issue list \
    --repo "$REPO" \
    --milestone "$COURSE_MILESTONE" \
    --state all \
    --limit 100 \
    --json number,title,state \
    --jq '.[] | "#\(.number) [\(.state)] \(.title)"'

echo
echo "ENG-M0:"
gh issue list \
    --repo "$REPO" \
    --milestone "$ENG_M0_MILESTONE" \
    --state all \
    --limit 100 \
    --json number,title,state \
    --jq '.[] | "#\(.number) [\(.state)] \(.title)"'

echo
echo "ENG-M1:"
gh issue list \
    --repo "$REPO" \
    --milestone "$ENG_M1_MILESTONE" \
    --state all \
    --limit 100 \
    --json number,title,state \
    --jq '.[] | "#\(.number) [\(.state)] \(.title)"'

echo
echo "ST7789 experiment:"
gh issue list \
    --repo "$REPO" \
    --state all \
    --limit 500 \
    --search '"Prototype compact HMI on ST7789 display" in:title' \
    --json number,title,state \
    --jq '.[] | "#\(.number) [\(.state)] \(.title)"'

echo
echo "Done."
