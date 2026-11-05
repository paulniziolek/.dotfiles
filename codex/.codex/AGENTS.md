# Global agent instructions

## Instruction layering

- Machine-specific guidance lives in `~/.config/agents/machine.md`.
- If that file exists and its contents have not already been supplied by the
  current client, read and follow it before choosing an operating-system
  environment, shell, repository path, or installation method.
- Treat the machine guidance as additive to this file.
- Follow repository-level instruction files. Instructions closer to the files
  being changed take precedence when they conflict with broader guidance.
