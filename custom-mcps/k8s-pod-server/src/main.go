package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func main() {
	// Create Kubernetes client
	config, err := rest.InClusterConfig()
	if err != nil {
		log.Printf("Failed to get in-cluster config: %v. Falling back to external config (for local testing)", err)
		// Try fallback or just use it as is
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Printf("Failed to create clientset: %v", err)
	}

	// Create MCP server
	s := server.NewMCPServer(
		"k8s-pod-mcp-server",
		"1.0.0",
		server.WithLogging(),
	)

	// Add get_pods tool
	tool := mcp.NewTool("get_pods",
		mcp.WithDescription("Get a list of pods in a specified Kubernetes namespace"),
	)
	tool.InputSchema.Type = "object"
	tool.InputSchema.Properties = map[string]any{
		"namespace": map[string]any{
			"type":        "string",
			"description": "The namespace to list pods from",
			"default":     "default",
		},
	}

	s.AddTool(tool, func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		arguments := request.Params.Arguments
		argsMap, ok := arguments.(map[string]any)
		if !ok {
			return mcp.NewToolResultError("invalid arguments"), nil
		}

		namespace, ok := argsMap["namespace"].(string)
		if !ok {
			namespace = "default"
		}

		podList, err := clientset.CoreV1().Pods(namespace).List(ctx, metav1.ListOptions{})
		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("Failed to list pods: %v", err)), nil
		}

		var pods []string
		for _, pod := range podList.Items {
			pods = append(pods, pod.Name)
		}

		return mcp.NewToolResultText(fmt.Sprintf("%v", pods)), nil
	})

	// Use SSE handler for MCP
	sseServer := server.NewSSEServer(s)
	
	// Logging middleware
	loggingHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Incoming request: %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
		
		if r.URL.Path == "/sse" {
			sseServer.ServeHTTP(w, r)
			return
		}

		if r.URL.Path == "/mcp" {
			if r.Method == http.MethodPost {
				// Handle Streamable HTTP (standalone POST requests)
				var request struct {
					JSONRPC string          `json:"jsonrpc"`
					ID      interface{}     `json:"id"`
					Method  string          `json:"method"`
					Params  json.RawMessage `json:"params"`
				}
				
				body, _ := io.ReadAll(r.Body)
				log.Printf("Request body: %s", string(body))
				
				if err := json.Unmarshal(body, &request); err != nil {
					http.Error(w, "Invalid JSON", http.StatusBadRequest)
					return
				}

				var response struct {
					JSONRPC string      `json:"jsonrpc"`
					ID      interface{} `json:"id"`
					Result  interface{} `json:"result,omitempty"`
					Error   interface{} `json:"error,omitempty"`
				}
				response.JSONRPC = "2.0"
				response.ID = request.ID

				switch request.Method {
				case "initialize":
					response.Result = map[string]interface{}{
						"protocolVersion": "2024-11-05",
						"capabilities": map[string]interface{}{
							"tools": map[string]interface{}{
								"listChanged": false,
							},
						},
						"serverInfo": map[string]interface{}{
							"name":    "k8s-pod-mcp-server",
							"version": "0.1.0",
						},
					}
				case "notifications/initialized":
					// No response needed for notifications
					w.WriteHeader(http.StatusNoContent)
					return
				case "tools/list":
					response.Result = map[string]interface{}{
						"tools": []interface{}{
							map[string]interface{}{
								"name":        "get_pods",
								"description": "List all pods in the specified namespace",
								"inputSchema": map[string]interface{}{
									"type": "object",
									"properties": map[string]interface{}{
										"namespace": map[string]interface{}{
											"type":        "string",
											"description": "The Kubernetes namespace to list pods from",
											"default":     "default",
										},
									},
								},
							},
						},
					}
				case "tools/call":
					// Handle tool calls for standalone POST
					var params struct {
						Name      string                 `json:"name"`
						Arguments map[string]interface{} `json:"arguments"`
					}
					json.Unmarshal(request.Params, &params)
					
					if params.Name == "get_pods" {
						ns, ok := params.Arguments["namespace"].(string)
						if !ok {
							ns = "default"
						}
						podList, err := clientset.CoreV1().Pods(ns).List(r.Context(), metav1.ListOptions{})
						if err != nil {
							response.Error = map[string]interface{}{
								"code":    -32000,
								"message": fmt.Sprintf("Failed to list pods: %v", err),
							}
						} else {
							var pods []string
							for _, pod := range podList.Items {
								pods = append(pods, pod.Name)
							}
							response.Result = map[string]interface{}{
								"content": []interface{}{
									map[string]interface{}{
										"type": "text",
										"text": fmt.Sprintf("%v", pods),
									},
								},
							}
						}
					}
				default:
					// For other methods, try to use sseServer's session logic (will likely fail for kagent)
					sseServer.ServeHTTP(w, r)
					return
				}

				respBody, _ := json.Marshal(response)
				w.Header().Set("Content-Type", "application/json")
				w.Write(respBody)
				return
			}
			sseServer.ServeHTTP(w, r)
			return
		}
		
		http.NotFound(w, r)
	})

	log.Println("Starting SSE MCP server on :3000")
	log.Println("SSE endpoint: http://localhost:3000/sse")
	log.Println("Message endpoint: http://localhost:3000/mcp")
	
	if err := http.ListenAndServe(":3000", loggingHandler); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
