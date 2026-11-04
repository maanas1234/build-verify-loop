# Build verify loop

A skill for Claude Code (or any coding agent) working in swayu-app.
The agent that builds a change never decides it is done: checks pass first, then a separate verifier says YES. For outcome words and pictures, a quality judge reads the finished page against a rubric and references.

## Install

```
mkdir -p ~/.claude/skills/build-verify-loop
cp SKILL.md verify.sh known-failures.txt ~/.claude/skills/build-verify-loop/
chmod +x ~/.claude/skills/build-verify-loop/verify.sh
```

Your agent then picks it up on its own, or you can call it with `/build-verify-loop`.
For Codex or another agent, paste SKILL.md into its instructions.
