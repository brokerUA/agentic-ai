#!/bin/bash
set -e

echo "Verifying Agentic Infrastructure..."

# Check if Gateway API CRDs are installed
if kubectl get gatewayclasses > /dev/null 2>&1; then
  echo "✅ Gateway API CRDs are present."
else
  echo "❌ Gateway API CRDs are missing."
  exit 1
fi

# Check if agentgateway is running
if kubectl get pods -n agentgateway-system -l app.kubernetes.io/name=agentgateway | grep Running > /dev/null 2>&1; then
  echo "✅ Agentgateway is running."
else
  echo "⚠️ Agentgateway is not running yet (check deployment status)."
fi

# Check if kagent controller is running
if kubectl get pods -A | grep -E "kagent-operator|kagent-controller" | grep Running > /dev/null 2>&1; then
  echo "✅ KAgent Controller is running."
else
  echo "⚠️ KAgent Controller is not running yet."
fi

# Check if the agent CRD is deployed
if kubectl get agent basic-agent -n kagent > /dev/null 2>&1; then
  echo "✅ Basic Agent CRD is deployed."
  # Check agent status
  PHASE=$(kubectl get agent basic-agent -n kagent -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ -z "$PHASE" ]; then
    PHASE=$(kubectl get agent basic-agent -n kagent -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    [ "$PHASE" == "True" ] && PHASE="Ready"
    [ "$PHASE" == "False" ] && PHASE="NotReady"
    [ "$PHASE" == "Unknown" ] && PHASE="Unknown"
  fi
  echo "Agent Phase: ${PHASE:-Unknown}"
  
  # Check for errors in status conditions
  ERROR=$(kubectl get agent basic-agent -n kagent -o jsonpath='{.status.conditions[?(@.status=="False")].message}' 2>/dev/null)
  if [ ! -z "$ERROR" ]; then
    echo "⚠️ Agent Error: $ERROR"
  fi
else
  echo "⚠️ Basic Agent CRD is not deployed."
fi

echo "Infrastructure verification complete."
