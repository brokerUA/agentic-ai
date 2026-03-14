#!/bin/bash
set -e

# Wait for agent readiness (optional but helpful)
echo "Checking if agentgateway is running..."
kubectl get pods -n agentgateway-system -l app.kubernetes.io/name=agentgateway | grep Running > /dev/null 2>&1 || { echo "❌ Agentgateway is not running. Please run 'mise run verify' first."; exit 1; }

# Port-forward to access the gateway
echo "Setting up port-forward to agentgateway..."

# Function to terminate port-forward on exit
terminate_pf() {
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap terminate_pf EXIT

# Check if port 8080 is already in use
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    # If it's a kubectl port-forward process, we might want to kill it to ensure a fresh connection
    PID_ON_PORT=$(lsof -Pi :8080 -sTCP:LISTEN -t)
    # Check if this PID belongs to kubectl
    if ps -p "$PID_ON_PORT" -o comm= | grep -q "kubectl"; then
        echo "⚠️ Port 8080 is occupied by an existing kubectl port-forward (PID $PID_ON_PORT). Cleaning up..."
        kill "$PID_ON_PORT" 2>/dev/null || true
        sleep 1
    else
        echo "⚠️ Port 8080 is already in use by another process. Skipping port-forward and hoping it's the right one."
    fi
fi

# Try to find the service name - in KGway mode it might be different from Gateway name
# Usually it's the Helm release name 'agentgateway' or prefixed with 'gwy-'
SVC_NAME="agentgateway"
if ! kubectl get svc -n agentgateway-system "$SVC_NAME" >/dev/null 2>&1; then
    SVC_NAME="gwy-agent-gateway"
    if ! kubectl get svc -n agentgateway-system "$SVC_NAME" >/dev/null 2>&1; then
        SVC_NAME="agent-gateway"
        if ! kubectl get svc -n agentgateway-system "$SVC_NAME" >/dev/null 2>&1; then
            echo "❌ Gateway service not found in namespace 'agentgateway-system'."
            echo "   Tried names: agentgateway, gwy-agent-gateway, agent-gateway"
            echo "   Check if the gateway was deployed correctly with 'mise run deploy-agentgateway'."
            exit 1
        fi
    fi
fi

# If port is still in use (by non-kubectl process), we skip port-forward
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    PF_PID=""
else
    echo "Using service '$SVC_NAME' for port-forward."
    kubectl port-forward -n agentgateway-system "svc/$SVC_NAME" 8080:8080 > /dev/null 2>&1 &
    PF_PID=$!
    # Wait for connection to be established
    echo "Waiting for port-forward to be ready..."
    MAX_RETRIES=10
    RETRY_COUNT=0
    while ! curl -s "http://localhost:8080/v1/chat/completions" -H "Host: model.agent.internal" > /dev/null 2>&1; do
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
fi

echo "Sending a request to verify the agent's context..."
# Use OpenAI-compatible API format
# Host 'model.agent.internal' is defined in HTTPRoute
# Ask the agent who it is to confirm systemMessage usage
RESPONSE=$(curl -s -X POST "http://localhost:8080/v1/chat/completions" \
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
AGENT_CONTENT=$(echo "$RESPONSE" | grep -o '"content": *"[^"]*"' | head -1 | sed 's/"content": *//;s/"//g')
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
