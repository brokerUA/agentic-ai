#!/bin/bash
set -e

# Wait for agent readiness (optional but helpful)
echo "Checking if agentgateway is running..."
kubectl get pods -n agentgateway-system -l app.kubernetes.io/name=agentgateway | grep Running > /dev/null 2>&1 || { echo "❌ Agentgateway is not running. Please run 'mise run verify' first."; exit 1; }

# Port-forward to access the gateway
PORT=8080
# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    PID_ON_PORT=$(lsof -Pi :$PORT -sTCP:LISTEN -t | head -n 1)
    # Check if this PID belongs to kubectl port-forward
    if ps -p "$PID_ON_PORT" -o comm= | grep -q "kubectl"; then
        echo "⚠️ Port $PORT is occupied by an existing kubectl port-forward (PID $PID_ON_PORT). Cleaning up..."
        kill "$PID_ON_PORT" 2>/dev/null || true
        sleep 1
    else
        echo "⚠️ Port $PORT is already in use by another process ($(ps -p "$PID_ON_PORT" -o comm=)). Trying a different port..."
        # Find a free port starting from 8081
        PORT=8081
        while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; do
            PORT=$((PORT+1))
        done
        echo "Using alternative port $PORT"
    fi
fi

echo "Setting up port-forward to agentgateway on port $PORT..."

# Try to find the service name - in KGway mode it might be different from Gateway name
# Usually it's the Helm release name 'agentgateway' or prefixed with 'gwy-'
SVC_NAME="agent-gateway"
if ! kubectl get svc -n agentgateway-system "$SVC_NAME" >/dev/null 2>&1; then
    SVC_NAME="gwy-agent-gateway"
    if ! kubectl get svc -n agentgateway-system "$SVC_NAME" >/dev/null 2>&1; then
        SVC_NAME="agentgateway"
        if ! kubectl get svc -n agentgateway-system "$SVC_NAME" >/dev/null 2>&1; then
            echo "❌ Gateway service not found in namespace 'agentgateway-system'."
            echo "   Tried names: agent-gateway, gwy-agent-gateway, agentgateway"
            echo "   Check if the gateway was deployed correctly with 'mise run deploy-agentgateway'."
            exit 1
        fi
    fi
fi

# Function to terminate port-forward on exit
terminate_pf() {
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap terminate_pf EXIT

echo "Using service '$SVC_NAME' for port-forward."
kubectl port-forward -n agentgateway-system "svc/$SVC_NAME" "$PORT:8080" > /dev/null 2>&1 &
PF_PID=$!
# Wait for connection to be established
echo "Waiting for port-forward on port $PORT to be ready..."
MAX_RETRIES=15
RETRY_COUNT=0
while ! curl -s "http://localhost:$PORT/v1/chat/completions" -H "Host: model.agent.internal" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "❌ Timeout waiting for port-forward to be ready."
        exit 1
    fi
    # Check if port-forward process is still running
    if ! kill -0 $PF_PID 2>/dev/null; then
        echo "❌ Port-forward process died prematurely."
        exit 1
    fi
    sleep 1
done

echo "Sending a request to verify the agent's context..."
# Use OpenAI-compatible API format
# Host 'model.agent.internal' is defined in HTTPRoute
# Ask the agent who it is to confirm systemMessage usage
RESPONSE=$(curl -s -X POST "http://localhost:$PORT/v1/chat/completions" \
  -H "Host: model.agent.internal" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-2.5-flash-lite",
    "messages": [
      {"role": "user", "content": "Who are you and what is your goal in this environment? Mention the specific infrastructure you are running in."}
    ]
  }')

echo "----------------------------------------"
echo "Agent Response:"

# Parse response with python if possible
if command -v python3 >/dev/null 2>&1; then
    AGENT_CONTENT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null || echo "")
else
    AGENT_CONTENT=$(echo "$RESPONSE" | grep -o '"content": *"[^"]*"' | head -1 | sed 's/"content": *//;s/"//g')
fi

if [ -z "$AGENT_CONTENT" ]; then
    echo "Full Raw Response for Debugging:"
    echo "$RESPONSE"
else
    echo -e "\033[1;32m$AGENT_CONTENT\033[0m"
fi
echo "----------------------------------------"

# Check if agent mentioned Kubernetes or infrastructure as set in systemMessage
if [[ $AGENT_CONTENT == *"Kubernetes"* || $AGENT_CONTENT == *"infrastructure"* || $AGENT_CONTENT == *"agentic"* ]]; then
  echo "✅ Success! Agent is using the configured systemMessage and is aware of its environment."
elif [[ $RESPONSE == *"content"* ]]; then
  echo "⚠️ Agent responded, but might not have used the specific systemMessage context."
else
  echo "❌ Error: Failed to get a valid response from the agent."
  exit 1
fi
