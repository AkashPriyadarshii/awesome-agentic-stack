# Contributing to awesome-agentic-stack

Thank you for contributing! To maintain high credibility and signal-to-noise ratio, we enforce a strict quality gate. We value survival under constraint over simple existence.

---

## ⚡ Submission Guidelines

1. **Suggest a New Tool**: Open a GitHub Issue using our structured [Tool Suggestion Template](.github/ISSUE_TEMPLATE/suggest_tool.md).
2. **Report a Dead/Paid Tool**: Open a GitHub Issue using our [Report Dead Tool Template](.github/ISSUE_TEMPLATE/report_dead_tool.md).
3. **Submit a Pull Request**: Only submit a PR *after* the corresponding Issue has been approved by a maintainer.
   - Submit one tool per PR.
   - Target the `main` branch.

---

## 🛡️ The Quality Gate (All must pass)

Before proposing any tool, verify it passes these criteria:

- **Actively Maintained**: The repository must have at least one commit in the last 3 months.
- **₹0 Enforced**: The tool must offer a fully usable free tier with zero payment details or credit cards required. 
  - *Note: If a credit card is required to unlock a free tier, it will be flagged with a ⚠️, not necessarily rejected.*
- **Non-Redundant**: It must not duplicate the exact core function of a tool already listed unless it is demonstrably better (e.g., faster, lower resource usage).
- **Workflow Fit**: It must fit directly into one of our workflow phases (Phase 0 to Phase 4). You must state the target phase in your suggestion.
- **Independent Star Counts**: Do not copy star counts from the source list. All new entries should use the `⭐ verify` placeholder in PRs so we can run our verification scripts on them.

---

## 📝 README Entry Format

Ensure your proposed entry follows this exact table row format:

```markdown
| [tool-name](https://github.com/author/tool-name) | ⭐ verify | ✅ | Survival verdict in one clean, terse line. |
```

- **Free Tier Labels:**
  - ✅ **Free** — zero payment method required
  - ⚠️ **Free-ish** — free tier exists but credit card required to unlock
  - ❌ **Paid** — no meaningful free tier
