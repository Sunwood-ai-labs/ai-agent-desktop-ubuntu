# Agent Workflow Rules

## Commit and Push Policy
- For any file change task, create commits in small logical units instead of one large commit.
- Commit message titles must be in English and must start with an emoji.
- Push commits to `origin` after the task is completed unless the user explicitly says not to push.
- Apply this policy automatically on repeated requests; do not wait for another reminder.

## Release Notes Policy
- When creating or updating release notes, always base the content on actual Git differences and commit history.
- Prefer detailed, substantial release notes over short summaries; include concrete Added/Changed/Removed points when available.
- Add emojis to all level-2 markdown headings (`## ...`) in release notes.
- Apply this policy automatically on repeated requests unless the user explicitly asks for a different style.
