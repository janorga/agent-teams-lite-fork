#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Agent Teams Lite — Install Script
# Copies skills to your AI coding assistant's skill directory
# Cross-platform: macOS, Linux, Windows (Git Bash / WSL)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_DIR/skills"

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin)  OS="macos" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="wsl"
            else
                OS="linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)  OS="windows" ;;
        *)  OS="unknown" ;;
    esac
}

os_label() {
    case "$OS" in
        macos)   echo "macOS" ;;
        linux)   echo "Linux" ;;
        wsl)     echo "WSL" ;;
        windows) echo "Windows (Git Bash)" ;;
        *)       echo "Unknown" ;;
    esac
}

# ============================================================================
# Color support
# ============================================================================

setup_colors() {
    if [[ "$OS" == "windows" ]] && [[ -z "${WT_SESSION:-}" ]] && [[ -z "${TERM_PROGRAM:-}" ]]; then
        # Plain CMD without Windows Terminal — no ANSI support
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
    else
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        NC='\033[0m'
    fi
}

# ============================================================================
# Path Resolution
# ============================================================================

get_tool_path() {
    local tool="$1"
    case "$tool" in
        claude-code)
            case "$OS" in
                windows)  echo "$USERPROFILE/.claude/skills" ;;
                wsl)      echo "$HOME/.claude/skills" ;;
                *)        echo "$HOME/.claude/skills" ;;
            esac
            ;;
        opencode)
            case "$OS" in
                windows)  echo "$APPDATA/opencode/skill" ;;
                macos)    echo "$HOME/.config/opencode/skill" ;;
                *)        echo "$HOME/.config/opencode/skill" ;;
            esac
            ;;
        opencode-commands)
            case "$OS" in
                windows)  echo "$APPDATA/opencode/commands" ;;
                macos)    echo "$HOME/.config/opencode/commands" ;;
                *)        echo "$HOME/.config/opencode/commands" ;;
            esac
            ;;
        gemini-cli)
            case "$OS" in
                windows)  echo "$USERPROFILE/.gemini/skills" ;;
                wsl)      echo "$HOME/.gemini/skills" ;;
                *)        echo "$HOME/.gemini/skills" ;;
            esac
            ;;
        codex)
            case "$OS" in
                windows)  echo "$USERPROFILE/.codex/skills" ;;
                wsl)      echo "$HOME/.codex/skills" ;;
                *)        echo "$HOME/.codex/skills" ;;
            esac
            ;;
        vscode)      echo "./.vscode/skills" ;;
        antigravity) echo "./.vscode/skills" ;;
        cursor)
            case "$OS" in
                windows)  echo "$USERPROFILE/.cursor/skills" ;;
                wsl)      echo "$HOME/.cursor/skills" ;;
                *)        echo "$HOME/.cursor/skills" ;;
            esac
            ;;
        project-local) echo "./skills" ;;
    esac
}

# ============================================================================
# Helpers
# ============================================================================

make_writable() {
    if [[ "$OS" != "windows" ]]; then
        chmod u+w "$1" 2>/dev/null || true
    fi
}

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║      Agent Teams Lite — Installer        ║${NC}"
    echo -e "${CYAN}${BOLD}║   Spec-Driven Development for AI Agents  ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Detected:${NC} $(os_label)"
    echo ""
}

print_skill() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_next_step() {
    local config_file="$1"
    local example_file="$2"
    echo -e "\n${YELLOW}Next step:${NC} Add the orchestrator to your ${BOLD}$config_file${NC}"
    echo -e "  See: ${CYAN}$example_file${NC}"
}

print_engram_note() {
    echo -e "\n${YELLOW}Recommended persistence backend:${NC} ${BOLD}Engram${NC}"
    echo -e "  ${CYAN}https://github.com/gentleman-programming/engram${NC}"
    echo -e "  If Engram is available, it will be used automatically (recommended)"
    echo -e "  If not, falls back to ${BOLD}none${NC} — enable ${BOLD}engram${NC} or ${BOLD}openspec${NC} for better results"
}

show_help() {
    echo "Usage: install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --agent NAME    Install for a specific agent (non-interactive)"
    echo "  --path DIR      Custom install path (use with --agent custom)"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Agents: claude-code, opencode, gemini-cli, codex, vscode, antigravity, cursor, project-local, all-global"
}

# ============================================================================
# Install functions
# ============================================================================

install_skills() {
    local target_dir="$1"
    local tool_name="$2"

    echo -e "\n${BLUE}Installing skills for ${BOLD}$tool_name${NC}${BLUE}...${NC}"

    mkdir -p "$target_dir"

    local count=0
    for skill_dir in "$SKILLS_SRC"/sdd-*/; do
        local skill_name
        skill_name=$(basename "$skill_dir")
        mkdir -p "$target_dir/$skill_name" 2>/dev/null || {
            make_writable "$target_dir/$skill_name"
        }
        if [ -f "$target_dir/$skill_name/SKILL.md" ]; then
            make_writable "$target_dir/$skill_name/SKILL.md"
        fi
        cp "$skill_dir/SKILL.md" "$target_dir/$skill_name/SKILL.md"
        print_skill "$skill_name"
        count=$((count + 1))
    done

    echo -e "\n  ${GREEN}${BOLD}$count skills installed${NC} → $target_dir"
}

install_opencode_commands() {
    local commands_src="$REPO_DIR/examples/opencode/commands"
    local commands_target
    commands_target="$(get_tool_path opencode-commands)"

    echo -e "\n${BLUE}Installing OpenCode commands...${NC}"

    mkdir -p "$commands_target"

    local count=0
    for cmd_file in "$commands_src"/sdd-*.md; do
        local cmd_name
        cmd_name=$(basename "$cmd_file")
        cp "$cmd_file" "$commands_target/$cmd_name"
        print_skill "${cmd_name%.md}"
        count=$((count + 1))
    done

    echo -e "\n  ${GREEN}${BOLD}$count commands installed${NC} → $commands_target"
}

# ============================================================================
# Agent install dispatcher
# ============================================================================

install_for_agent() {
    local agent="$1"

    case "$agent" in
        claude-code)
            install_skills "$(get_tool_path claude-code)" "Claude Code"
            print_next_step "~/.claude/CLAUDE.md" "examples/claude-code/CLAUDE.md"
            ;;
        opencode)
            install_skills "$(get_tool_path opencode)" "OpenCode"
            install_opencode_commands
            print_next_step "~/.config/opencode/opencode.json" "examples/opencode/opencode.json"
            ;;
        gemini-cli)
            install_skills "$(get_tool_path gemini-cli)" "Gemini CLI"
            print_next_step "~/.gemini/GEMINI.md" "examples/gemini-cli/GEMINI.md"
            ;;
        codex)
            install_skills "$(get_tool_path codex)" "Codex"
            print_next_step "Codex instructions file" "examples/codex/agents.md"
            ;;
        vscode)
            install_skills "$(get_tool_path vscode)" "VS Code (Copilot)"
            print_next_step ".github/copilot-instructions.md" "examples/vscode/copilot-instructions.md"
            echo -e "  ${YELLOW}Note:${NC} Skills installed in current project (.vscode/skills/)"
            ;;
        antigravity)
            install_skills "$(get_tool_path antigravity)" "Antigravity"
            print_next_step ".github/copilot-instructions.md" "examples/vscode/copilot-instructions.md (same as VS Code)"
            echo -e "  ${YELLOW}Note:${NC} Antigravity uses VS Code config paths"
            ;;
        cursor)
            install_skills "$(get_tool_path cursor)" "Cursor"
            print_next_step ".cursorrules" "examples/cursor/.cursorrules"
            ;;
        project-local)
            install_skills "$(get_tool_path project-local)" "Project-local"
            echo -e "\n${YELLOW}Note:${NC} Skills installed in ${BOLD}./skills/${NC} — relative to this project"
            ;;
        all-global)
            install_skills "$(get_tool_path claude-code)" "Claude Code"
            install_skills "$(get_tool_path opencode)" "OpenCode"
            install_opencode_commands
            install_skills "$(get_tool_path gemini-cli)" "Gemini CLI"
            install_skills "$(get_tool_path codex)" "Codex"
            install_skills "$(get_tool_path cursor)" "Cursor"
            echo -e "\n${YELLOW}Next steps:${NC}"
            echo -e "  1. Add orchestrator to ${BOLD}~/.claude/CLAUDE.md${NC}"
            echo -e "  2. Add orchestrator agent to ${BOLD}~/.config/opencode/opencode.json${NC}"
            echo -e "  3. Add orchestrator to ${BOLD}~/.gemini/GEMINI.md${NC}"
            echo -e "  4. Add orchestrator to ${BOLD}Codex instructions file${NC}"
            echo -e "  5. Add SDD rules to ${BOLD}.cursorrules${NC}"
            ;;
        custom)
            if [[ -z "${CUSTOM_PATH:-}" ]]; then
                read -rp "Enter target path: " CUSTOM_PATH
            fi
            install_skills "$CUSTOM_PATH" "Custom"
            ;;
        *)
            print_error "Unknown agent: $agent"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# ============================================================================
# Interactive menu
# ============================================================================

interactive_menu() {
    echo -e "${BOLD}Select your AI coding assistant:${NC}\n"
    echo "  1) Claude Code    ($(get_tool_path claude-code))"
    echo "  2) OpenCode       ($(get_tool_path opencode))"
    echo "  3) Gemini CLI     ($(get_tool_path gemini-cli))"
    echo "  4) Codex          ($(get_tool_path codex))"
    echo "  5) VS Code        ($(get_tool_path vscode))"
    echo "  6) Antigravity    ($(get_tool_path antigravity))"
    echo "  7) Cursor         ($(get_tool_path cursor))"
    echo "  8) Project-local  ($(get_tool_path project-local))"
    echo "  9) All global     (Claude Code + OpenCode + Gemini CLI + Codex + Cursor)"
    echo "  10) Custom path"
    echo ""
    read -rp "Choice [1-10]: " choice

    case $choice in
        1)  install_for_agent "claude-code" ;;
        2)  install_for_agent "opencode" ;;
        3)  install_for_agent "gemini-cli" ;;
        4)  install_for_agent "codex" ;;
        5)  install_for_agent "vscode" ;;
        6)  install_for_agent "antigravity" ;;
        7)  install_for_agent "cursor" ;;
        8)  install_for_agent "project-local" ;;
        9)  install_for_agent "all-global" ;;
        10) install_for_agent "custom" ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# ============================================================================
# Main
# ============================================================================

# Detect OS first — needed for colors and paths
detect_os

# Setup colors based on OS + terminal capabilities
setup_colors

# Parse arguments
AGENT=""
CUSTOM_PATH=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --agent)  AGENT="$2"; shift 2 ;;
        --path)   CUSTOM_PATH="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *)  echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

print_header

if [[ -n "$AGENT" ]]; then
    # Non-interactive mode
    install_for_agent "$AGENT"
else
    # Interactive mode
    interactive_menu
fi

echo -e "\n${GREEN}${BOLD}Done!${NC} Start using SDD with: ${CYAN}/sdd-init${NC} in your project\n"
print_engram_note
echo ""
