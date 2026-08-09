# Rejection Notes

> **Status: the audit was aspirational, not real.** Early versions of this project claimed "386 repos audited, 96 survived" and a rejection list of 290 repos. That claim overstated the work — the list was never actually audited at that scale, and the old rejection list contained placeholder entries.

The 96 tools currently listed were curated for three constraints:

- **₹0**: runs on a free tier, no payment method or credit card required (exceptions explicitly flagged).
- **Workflow-first**: included because it's useful mid-session for terminal/agent-based coding, not because it's popular.
- **Maintainable**: a tool that adds a paid tier or stops being maintained should be flagged and removed.

The rejection taxonomy below documents the *reasons* a tool can drop out. If a listed tool has since added a paid tier, changed its pricing, or gone unmaintained, open an Issue — the list is a living document, not a one-time dump.

## Rejection Reason Taxonomy

- **DEAD**: Last commit more than 6 months ago.
- **CC_REQUIRED**: Free tier claimed, but credit card/payment method required to register.
- **OVERLAP**: Performs the same role as an included tool but is less performant, bulkier, or harder to set up.
- **SCOPE_CREEP**: Interesting concept, but not workflow-critical for active terminal/agent coding.
- **UNVERIFIABLE**: Repo stats, star counts, or functional claims could not be independently verified.
- **UNMAINTAINED**: Active issue backlog with zero maintainer responses for 3+ months.
- **PAID_ONLY**: No meaningful free tier; requires paid subscription.
