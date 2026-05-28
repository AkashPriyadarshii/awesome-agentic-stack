# 🔄 The FOSS Agentic Coding Workflow (₹0 Stack)

A systematic, 4-phase development workflow engineered for solo vibe coders and indie hackers working with tight resource constraints (e.g., Realme GT7 Phone + MacBook Air M5) under ₹0 tool budgets.

---

## 1. The Full Loop

```
+---------------------------------------------------------------------------------+
|                                                                                 |
|                        PHASE 0: IDENTITY LAYER (Once)                           |
|      Drop project rule files & inject context before prompt #1                   |
|      [AGENTS.md] -> [SPEC.md] -> [DESIGN.md] -> [CLAUDE.md] -> taste-skill      |
|                                                                                 |
+----------------------------------------+----------------------------------------+
                                         |
                                         v
+---------------------------------------------------------------------------------+
|                                                                                 |
|                       PHASE 1: SESSION START (Pre-Flight)                       |
|      Reduce tokens by 60-90% immediately before calling your agent               |
|      repomix (Pack Codebase) -> rtk start (Token Killer) -> auto-memory recall  |
|                                                                                 |
+----------------------------------------+----------------------------------------+
                                         |
                                         v
+---------------------------------------------------------------------------------+
|                                                                                 |
|                       PHASE 2: ACTIVE CODING (The Run)                          |
|      Write code inside optimized TUIs & bridges with side-by-side terminal logs |
|      cc-switch / cmux -> ralph (Autonomous Loop) -> free-claude-code bridge     |
|                                                                                 |
+----------------------------------------+----------------------------------------+
                                         | (Sync always active)
                                         v
+---------------------------------------------------------------------------------+
|                                                                                 |
|                       PHASE 3: MOBILE & CROSS-DEVICE                            |
|      Hot-reload or prompt on phone (Realme GT7) when away from your keyboard    |
|      syncthing (Continuous Sync) -> slopus/happy (Mobile Web) -> droidclaw ADB  |
|                                                                                 |
+----------------------------------------+----------------------------------------+
                                         |
                                         v
+---------------------------------------------------------------------------------+
|                                                                                 |
|                        PHASE 4: SESSION END (Push Gate)                         |
|      Scan for leaked keys, compress memory summaries, push securely to GitHub   |
|      gitleaks detect -> auto-memory save -> git-surgeon / git-ai push           |
|                                                                                 |
+---------------------------------------------------------------------------------+
```

---

## 2. Phase 0 — Identity Layer

**Goal:** Establish strict guidelines to ensure the agent understands the repository architecture and avoids generating boring, bloated, or slop code.

### Execution:
1. **Drop Project Context files into root:**
   - `AGENTS.md`: Tells all incoming agents the project directories and scope boundaries.
   - `SPEC.md`: Outlines features to build before writing implementation code.
   - `DESIGN.md`: Explains your color palettes, fonts, spacing constraints, and dark-mode rules.
   - `CLAUDE.md`: Pre-configured rules for style sheets, frameworks, and testing standards.
2. **Install anti-slop rules:**
   - Drop `taste-skill` and `humanizer` configurations into your agent shell directories.
   - Inject Karpathy-approved prompt guidelines.

---

## 3. Phase 1 — Session Start

**Goal:** Clean out the agent's context window, pack the active directory, and reload prior session memory to minimize token usage by up to 90%.

### Commands & Tools:
1. **Pack the Codebase:**
   ```bash
   npx repomix --style xml --exclude "temp,dist,node_modules"
   ```
2. **Recall Memory:**
   ```bash
   auto-memory recall
   ```
3. **Compress Context & Kill Tokens:**
   ```bash
   rtk start --target repomix-output.xml
   ```

---

## 4. Phase 2 — Active Coding

**Goal:** Execute the code generation cycle inside efficient, side-by-side agent workspaces with automated verification loops.

### Execution:
1. **Workspace setup:**
   Launch `cc-switch` or run a customized `cmux` window layout in Ghostty or kitty terminal:
   - Panel 1: Active agent process (e.g., Claude Code, Gemini CLI, OpenCode).
   - Panel 2: Live build runner/web dev server (`npm run dev`).
   - Panel 3: Token burn monitor (`codeburn`).
2. **Continuous Generation Loop:**
   Use `ralph` to execute complex multi-step refactoring loops without human intervention:
   ```bash
   ralph run "Implement the billing checklist in SPEC.md and run tests"
   ```

---

## 5. Phase 3 — Mobile & Cross-Device

**Goal:** Keep your workspace perfectly mirrored between your main workstation (e.g., MacBook M5) and your phone (Realme GT7) for immediate vibe coding on the go.

### Execution:
1. **P2P Directory Mirroring:**
   Enable `syncthing` daemon processes on both devices. Any file change made by an agent on your laptop is mirrored to your phone directory in under 2 seconds.
2. **Voice Prompting on the Go:**
   Access the `slopus/happy` client on your phone's browser to send voice prompts and read files with AMOLED-black battery saving layouts.
3. **ADB Command Bridge:**
   Use `droidclaw` to inspect, tap, and test Android app interfaces straight from your laptop's terminal agent.

---

## 6. Phase 4 — Session End

**Goal:** Perform key leak checks, commit the exact code differences with descriptive summaries, and snapshot memory.

### Commands & Tools:
1. **Scan for Secrets:**
   ```bash
   gitleaks detect --source . --verbose
   ```
2. **Snapshot Session Memory:**
   ```bash
   auto-memory save "Implemented cart stripe webhooks, all tests green."
   ```
3. **Smart Agent Commit:**
   ```bash
   git-ai commit -m "feat(billing): add stripe webhooks"
   ```

---

## 7. Steal This Workflow

Here is the exact terminal script compilation to run the full workflow cycle. Drop this script as `loop.sh` in your user config directory:

```bash
#!/usr/bin/env bash
# ₹0 FOSS Agentic dev loop sequence

function session_start() {
  echo "⚡ Phase 1: Packing codebase & recalling context..."
  npx repomix . --style xml
  auto-memory recall
  rtk start --target repomix-output.xml
  echo "🚀 Workspace ready. Start your agent environment."
}

function session_end() {
  echo "🛡️ Phase 4: Running security gate & saving memory..."
  gitleaks detect --source .
  auto-memory save
  git-ai commit
  git push origin main
  echo "✅ Session closed and synchronized."
}

case "$1" in
  start)
    session_start
    ;;
  end)
    session_end
    ;;
  *)
    echo "Usage: loop.sh {start|end}"
    ;;
esac
```
