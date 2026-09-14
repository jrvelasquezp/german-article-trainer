#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# German Article Trainer
# Create PA-P0 subissues under the umbrella proposal issue
#
# Requirements:
#   - GitHub CLI (gh)
#   - authenticated with: gh auth login
#   - run from inside german-article-trainer repository
#   - labels and milestone should already exist
# ------------------------------------------------------------

PARENT_TITLE="Replace previous project proposal"
MILESTONE="PA-P0 — Proposal Replacement & Review"

echo "============================================================"
echo " German Article Trainer - PA-P0 subissue creation"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. Verify gh
# ------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) is not installed."
    echo "Install it and run this script again."
    exit 1
fi

# ------------------------------------------------------------
# 2. Verify authentication
# ------------------------------------------------------------

if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI is not authenticated."
    echo
    echo "Run:"
    echo "  gh auth login"
    exit 1
fi

# ------------------------------------------------------------
# 3. Detect repository
# ------------------------------------------------------------

REPO="$(gh repo view --json nameWithOwner -q '.nameWithOwner')"

if [[ -z "$REPO" ]]; then
    echo "ERROR: Could not detect GitHub repository."
    echo "Run this script from inside the repository."
    exit 1
fi

echo "Repository: $REPO"

# ------------------------------------------------------------
# 4. Find umbrella issue
# ------------------------------------------------------------

PARENT_NUMBER="$(
    gh issue list \
        --repo "$REPO" \
        --state all \
        --limit 200 \
        --json number,title \
        --jq ".[] | select(.title == \"$PARENT_TITLE\") | .number" \
        | head -n 1
)"

if [[ -z "$PARENT_NUMBER" ]]; then
    echo
    echo "ERROR: Parent issue not found:"
    echo "  $PARENT_TITLE"
    echo
    echo "Create the umbrella issue first, then run this script again."
    exit 1
fi

echo "Parent issue: #$PARENT_NUMBER - $PARENT_TITLE"

# ------------------------------------------------------------
# 5. Verify milestone exists
# ------------------------------------------------------------

if ! gh api "repos/$REPO/milestones?state=all&per_page=100" \
    --jq '.[].title' | grep -Fxq "$MILESTONE"; then

    echo
    echo "ERROR: Milestone does not exist:"
    echo "  $MILESTONE"
    echo
    echo "Create the milestone first."
    exit 1
fi

echo "Milestone: $MILESTONE"
echo

# ------------------------------------------------------------
# Helper: check whether issue already exists
# ------------------------------------------------------------

issue_exists() {
    local title="$1"

    gh issue list \
        --repo "$REPO" \
        --state all \
        --limit 300 \
        --json title \
        --jq '.[].title' \
        | grep -Fxq "$title"
}

# ------------------------------------------------------------
# Helper: create subissue
# ------------------------------------------------------------

create_subissue() {
    local title="$1"
    local labels="$2"
    local effort="$3"
    local objective="$4"
    local tasks="$5"
    local acceptance="$6"

    echo "------------------------------------------------------------"
    echo "Checking: $title"

    if issue_exists "$title"; then
        echo "SKIP: Issue already exists."
        return
    fi

    BODY="$(cat <<EOF
## Objective

$objective

## Tasks

$tasks

## Acceptance criteria

$acceptance

## Parent

#$PARENT_NUMBER — $PARENT_TITLE

## Estimated effort

$effort
EOF
)"

    CMD=(
        gh issue create
        --repo "$REPO"
        --title "$title"
        --body "$BODY"
        --milestone "$MILESTONE"
        --parent "$PARENT_NUMBER"
    )

    IFS=',' read -ra LABEL_ARRAY <<< "$labels"

    for label in "${LABEL_ARRAY[@]}"; do
        [[ -n "$label" ]] && CMD+=(--label "$label")
    done

    ISSUE_URL="$("${CMD[@]}")"

    echo "CREATED: $ISSUE_URL"
}

# ------------------------------------------------------------
# 6. Create PA-P0 subissues
# ------------------------------------------------------------

create_subissue \
"Review project title and keywords" \
"type:documentation,priority:high" \
"1 h" \
"Review and establish a concise project title and set of keywords consistent with the embedded-system and applied technological-development scope." \
"- [ ] Review current project title
- [ ] Verify that the title reflects the problem rather than a specific implementation platform
- [ ] Define concise project keywords
- [ ] Verify consistency with Electronic Engineering
- [ ] Update the proposal master document" \
"- Final title is defined
- Keywords are aligned with the project scope
- Neither title nor keywords unnecessarily constrain the project to a specific hardware platform
- Proposal master document is updated"


create_subissue \
"Review problem statement and justification" \
"type:documentation,type:research,priority:high" \
"2 h" \
"Review the problem statement and justification so they clearly describe the linguistic and technological problem addressed by the project." \
"- [ ] Review the Spanish-German grammatical gender problem
- [ ] Verify support for L1-L2 transfer claims
- [ ] Clarify the need for a dedicated embedded training system
- [ ] Remove unnecessary implementation-specific references
- [ ] Review alignment between problem and justification
- [ ] Update the proposal master document" \
"- Problem statement identifies the specific problem to be addressed
- Justification explains the relevance of the proposed technological solution
- Claims requiring academic support are identified or referenced
- Core argument remains independent from a specific implementation platform"


create_subissue \
"Review research question and objectives" \
"type:documentation,type:research,priority:high" \
"2 h" \
"Review the research question and objectives to ensure coherence with the proposed embedded technological solution." \
"- [ ] Review the research question
- [ ] Review the general objective
- [ ] Review each specific objective
- [ ] Verify correspondence between question and objectives
- [ ] Remove premature implementation commitments
- [ ] Verify that objectives are measurable within project scope" \
"- Research question is clearly stated
- General objective answers the project problem
- Specific objectives support completion of the general objective
- Objectives do not depend unnecessarily on Raspberry Pi, Python, ST7789, or another specific implementation technology"


create_subissue \
"Define preliminary theoretical framework" \
"type:research,type:documentation,priority:high" \
"3 h" \
"Develop the preliminary conceptual and theoretical framework required to support the project proposal." \
"- [ ] Define grammatical gender concepts relevant to German
- [ ] Define noun-article association
- [ ] Describe relevant L1-L2 transfer concepts
- [ ] Define embedded system concepts
- [ ] Define human-machine interaction concepts
- [ ] Define the role of natural language processing
- [ ] Define the limited role of generative AI
- [ ] Add preliminary academic references" \
"- Framework covers linguistic and technological foundations
- Terminology is consistent throughout the proposal
- Academic statements are supported by appropriate references
- Generative AI is described as a complementary component rather than the linguistic authority"


create_subissue \
"Define applied-project methodology" \
"type:documentation,type:research,priority:high" \
"3 h" \
"Define a methodology based on applied research, technological development, incremental implementation, and experimental validation." \
"- [ ] Define project methodological approach
- [ ] Define requirements-analysis stage
- [ ] Define architecture and design stage
- [ ] Define minimal prototype stage
- [ ] Define integration stage
- [ ] Define validation stage
- [ ] Define analysis and documentation stage
- [ ] Describe technology-selection criteria without fixing unnecessary implementation details" \
"- Methodology supports development of a functional technological prototype
- Development stages are clearly defined
- Validation activities are included
- Technology choices may be justified later using explicit technical criteria"


create_subissue \
"Define six-month project schedule" \
"type:documentation,priority:medium" \
"2 h" \
"Define a realistic six-month schedule covering proposal review, design, implementation, validation, analysis, and final documentation." \
"- [ ] Define project work packages
- [ ] Estimate duration of each work package
- [ ] Identify dependencies
- [ ] Allocate activities across six months
- [ ] Reserve time for integration and validation
- [ ] Reserve time for final documentation and defense preparation" \
"- Schedule covers the complete six-month project period
- Activities follow logical dependencies
- Implementation and validation have sufficient time allocation
- Schedule remains compatible with academic review cycles"


create_subissue \
"Define resources and preliminary budget" \
"type:documentation,type:hardware,priority:medium" \
"2 h" \
"Identify the resources required for the project and prepare a preliminary budget without unnecessarily fixing the implementation platform." \
"- [ ] Identify processing resources
- [ ] Identify display and interaction resources
- [ ] Identify development workstation requirements
- [ ] Identify software resources
- [ ] Identify instrumentation requirements
- [ ] Separate already-available resources from resources to acquire
- [ ] Prepare preliminary cost estimates
- [ ] Verify institutional treatment of owned resources" \
"- Required resource categories are documented
- Existing and additional resources are distinguishable
- Budget assumptions are explicit
- Specific hardware is only listed where appropriate as available or candidate implementation equipment"


create_subissue \
"Define expected products and indicators" \
"type:documentation,type:test,priority:high" \
"2 h" \
"Define the expected technological and academic products together with preliminary indicators for evaluating the prototype." \
"- [ ] Define functional prototype as expected product
- [ ] Define reproducible source repository
- [ ] Define technical documentation
- [ ] Define validation evidence
- [ ] Define functional correctness indicators
- [ ] Define response-time indicators
- [ ] Define computational-resource indicators
- [ ] Define operational stability indicators
- [ ] Define availability/degraded-operation criteria for optional external AI services" \
"- Expected products are measurable and appropriate for a technological-development project
- Each relevant result has at least one evaluation indicator
- Indicators can be measured during prototype validation
- Indicators do not depend on unselected implementation technologies"


create_subissue \
"Submit proposal draft for academic review" \
"type:documentation,priority:high" \
"2 h" \
"Prepare the consolidated German Article Trainer proposal draft and submit it for academic review before replacing the existing proposal in the institutional system." \
"- [ ] Consolidate all reviewed proposal sections
- [ ] Verify internal consistency
- [ ] Review formatting and references
- [ ] Generate review DOCX
- [ ] Verify document visually
- [ ] Store review version in repository
- [ ] Send proposal for academic review
- [ ] Record requested corrections as GitHub issues if applicable" \
"- Review-ready proposal is available
- Core proposal sections are internally consistent
- Review document is stored under docs/applied-project/proposal/drafts/
- Academic review has been requested
- Any resulting changes can be traced through GitHub issues"

# ------------------------------------------------------------
# 7. Summary
# ------------------------------------------------------------

echo
echo "============================================================"
echo " PA-P0 subissue creation complete"
echo "============================================================"
echo
echo "Parent issue:"
echo "  #$PARENT_NUMBER $PARENT_TITLE"
echo
echo "Current subissues:"
gh api \
    "repos/$REPO/issues/$PARENT_NUMBER/sub_issues" \
    --jq '.[] | "#\(.number)  \(.title)"'

echo
echo "Done."
