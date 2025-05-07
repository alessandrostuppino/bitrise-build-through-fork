#!/bin/bash

# CONFIGURATION
API_TOKEN="<API_TOKEN" # Bitrise > Profile > Account Settings > Security > Create token (better with no expiration).
BUILD_TRIGGER_TOKEN="<BUILD_TRIGGER_TOKEN>" # Bitrise > "Project" > Start build > Advanced > Generated cURL command (bottom) > "build_trigger_token".
APP_SLUG="<APP_SLUG>" # Bitrise > "Project" > from the URL "https://app.bitrise.io/app/<APP_SLUG>".
DEFAULT_WORKFLOW="<DEFAULT_WORKFLOW>" # Set the pre-selected workflow.

# Check for a passed-in branch name
if [[ -n "$1" ]]; then
  BRANCH_NAME="$1"
fi

if [[ -z "$BRANCH_NAME" ]]; then
  echo "❌ No branch provided."
  exit 1
fi

# Get author from Bitrise API
author_json=$(curl -s -X GET \
  "https://api.bitrise.io/v0.1/me" \
  -H "Authorization: ${API_TOKEN}")

# Try to get the Bitrise username, fall back to Git user.name if needed
AUTHOR=$(echo "$author_json" | jq -r '.data.username')
if [[ -z "$AUTHOR" || "$AUTHOR" == "null" ]]; then
  AUTHOR=$(git config --global user.name)
fi

# Fetch workflows
json=$(curl -s -X GET \
  "https://api.bitrise.io/v0.1/apps/${APP_SLUG}/build-workflows" \
  -H "Content-Type: application/json" \
  -H "Authorization: ${API_TOKEN}")

# Validate response
if [[ -z "$json" ]]; then
  echo "❌ No response from API."
  exit 1
fi

# Extract workflows
workflows=""
while IFS= read -r line; do
  workflows="$workflows"$'\n'"$line"
done < <(echo "$json" | jq -r '.data[]?')

workflows=$(echo "$workflows" | sed '/^\s*$/d')

if [[ -z "$workflows" ]]; then
  echo "❌ No workflows found. Check API token and app slug."
  exit 1
fi

# Build AppleScript dropdown list
apple_list=""
while IFS= read -r wf; do
  escaped_wf=$(echo "$wf" | sed 's/"/\\"/g')
  apple_list+="\"$escaped_wf\", "
done <<< "$workflows"
apple_list=${apple_list%, }

# Show dropdown and optional prompt for Message
read_selection=$(osascript -e '
  set workflows to {'"${apple_list}"'}
  set defaultWorkflow to "'"${DEFAULT_WORKFLOW}"'"
  set selectedWorkflow to choose from list workflows with prompt "Select a workflow to run on Bitrise" default items {defaultWorkflow}
  if selectedWorkflow is false then return "CANCELLED"
  
  set commitMessage to text returned of (display dialog "Message (optional)" default answer "")
  return (item 1 of selectedWorkflow) & "§" & commitMessage
')

if [[ "$read_selection" == "CANCELLED" || -z "$read_selection" ]]; then
  echo "❌ No workflow selected."
  exit 1
fi

# Clean selection
SELECTED_WORKFLOW="${read_selection%%§*}"
COMMIT_MESSAGE="${read_selection#*§}"

# Create the payload for the build endpoint
json_payload=$(jq -n \
  --arg branch "$BRANCH_NAME" \
  --arg workflow "$SELECTED_WORKFLOW" \
  --arg message "$COMMIT_MESSAGE" \
  --arg token "$BUILD_TRIGGER_TOKEN" \
  --arg author "$AUTHOR" \
  '{
    build_params: {
      branch: $branch,
      workflow_id: $workflow,
      commit_message: $message
    },
    hook_info: {
      build_trigger_token: $token,
      type: "bitrise"
    },
    triggered_by: ("Fork - @" + $author)
  }')

# Trigger the build
response=$(curl -s -X POST "https://app.bitrise.io/app/${APP_SLUG}/build/start.json" -L \
  -H "Content-Type: application/json" \
  --data "$json_payload")

# Parse response and extract build_url
build_url=$(echo "$response" | jq -r '.build_url')

# Check if we successfully got a build URL
if [[ -z "$build_url" ]]; then
  echo "❌ Failed to trigger the build or retrieve build URL."
  echo "Response: $response"
  exit 1
fi

# Show result
echo "👤 Author: $AUTHOR"
echo "✅ Build triggered for branch: $BRANCH_NAME"
echo "🔧 Workflow: $SELECTED_WORKFLOW"
echo "💬 Message: $COMMIT_MESSAGE"
echo -e "🔗 Build URL: $build_url"
