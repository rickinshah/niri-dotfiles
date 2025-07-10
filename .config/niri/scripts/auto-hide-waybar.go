package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
)

type Workspace struct {
	ActiveWindowID int    `json:"active_window_id"`
	ID             int    `json:"id"`
	IDX            int    `json:"idx"`
	IsActive       bool   `json:"is_active"`
	IsFocused      bool   `json:"is_focused"`
	IsUrgent       bool   `json:"is_urgent"`
	Name           string `json:"name"`
	Output         string `json:"output"`
}

type Window struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	AppID       string `json:"app_id"`
	PID         int    `json:"pid"`
	WorkspaceID int    `json:"workspace_id"`
	IsFocused   bool   `json:"is_focused"`
	IsFloating  bool   `json:"is_floating"`
	IsUrgent    bool   `json:"is_urgent"`
}

func getCurrentWorkspace() (*Workspace, error) {
	cmd := exec.Command("niri", "msg", "--json", "workspaces")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get workspace: %v", err)
	}

	var workspaces []*Workspace
	if err := json.Unmarshal(output, &workspaces); err != nil {
		return nil, fmt.Errorf("failed to parse workspace JSON: %v", err)
	}

	for _, ws := range workspaces {
		if ws.IsActive {
			return ws, nil
		}
	}

	return nil, fmt.Errorf("no active workspace")
}

func getWindows() ([]*Window, error) {
	cmd := exec.Command("niri", "msg", "--json", "windows")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to count windows: %v", err)
	}

	var windows []*Window
	if err := json.Unmarshal(output, &windows); err != nil {
		return nil, fmt.Errorf("failed to parse windows JSON: %v", err)
	}
	return windows, nil
}

func countWindowsInWorkspaceID(workspaceID int) (int, error) {
	windows, err := getWindows()
	if err != nil {
		return -1, err
	}

	count := 0
	for _, window := range windows {
		if window.WorkspaceID == workspaceID {
			count++
		}
	}

	return count, nil
}

func countTiledWindowsInWorkspaceID(workspaceID int) (int, error) {
	windows, err := getWindows()
	if err != nil {
		return -1, err
	}

	count := 0

	for _, window := range windows {
		if window.WorkspaceID == workspaceID && window.IsFloating == false {
			count++
		}
	}

	return count, nil
}

func countWindowInCurrentWorkspace() (int, error) {
	workspace, err := getCurrentWorkspace()
	if err != nil {
		return -1, err
	}

	count, err := countTiledWindowsInWorkspaceID(workspace.ID)
	if err != nil {
		return -1, err
	}
	return count, nil
}

func toggleWaybar() error {
	return exec.Command("killall", "-SIGUSR1", "waybar").Run()
}

const stateFile = "/tmp/waybar-visible"
const lockFile = "/tmp/waybar-lock"

func showWaybar() error {
	if _, err := os.Stat(stateFile); os.IsNotExist(err) {
		err := toggleWaybar()
		if err != nil {
			return err
		}
		file, err := os.Create(stateFile)
		if err != nil {
			return err
		}
		defer file.Close()
	}
	return nil
}

func hideWaybar() error {
	if _, err := os.Stat(stateFile); err == nil {
		err := toggleWaybar()
		if err != nil {
			return err
		}
		if err := os.Remove(stateFile); err != nil {
			return err
		}
	}
	return nil
}

func showOrHideWaybarBasedOnWindows() error {
	count, err := countWindowInCurrentWorkspace()
	if err != nil {
		return err
	}
	if count == 0 {
		return showWaybar()
	}
	return hideWaybar()
}

func waybarLocked() bool {
	if _, err := os.Stat(lockFile); err == nil {
		return true
	}
	return false
}

func main() {
	overviewMode := false

	if err := showOrHideWaybarBasedOnWindows(); err != nil {
		log.Println(err)
	}

	cmd := exec.Command("niri", "msg", "--json", "event-stream")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		line := scanner.Text()
		var event map[string]any
		if err := json.Unmarshal([]byte(line), &event); err != nil {
			continue
		}

		allowedEvents := map[string]bool{
			"WindowFocusChanged":    true,
			"WindowClosed":          true,
			"WindowOpenedOrChanged": true,
			"WorkspaceActivated":    true,
		}

		for eventType, eventValue := range event {
			if !waybarLocked() {
				if allowedEvents[eventType] && !overviewMode {
					if err := showOrHideWaybarBasedOnWindows(); err != nil {
						log.Println(err)
					}
					break
				} else if eventType == "OverviewOpenedOrClosed" {
					overview, ok := eventValue.(map[string]any)
					if !ok {
						log.Println("eventValue is not a map[string]any")
						break
					}

					isOpen, exists := overview["is_open"]
					if !exists {
						log.Println("is_open key is missing")
						break
					}

					overviewMode, ok = isOpen.(bool)
					if !ok {
						log.Println("is_open is not a bool")
						break
					}

					if overviewMode {
						_ = showWaybar()
					} else {
						_ = showOrHideWaybarBasedOnWindows()
					}
				}
			}
		}
	}

}
