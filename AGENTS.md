## About me
I'm Andrei Iurchenkov. You're my agent.

I'm the software engineer, which is usually works on distributed systems, defines architecture and technical direction.
I love to build software in very efficient way, keeping it simple and maintainable. So I wanted to share some of my coding preferences.

## Behavior preferences
- Preserve unrelated local changes.
- Keep changes within the request. Propose anything extra and explain why it helps.
- Questions asking for an explanation authorize investigation only. Do not modify files, install tools, or run builds/tests unless requested. Requests to make a change, including "Can you fix this?", authorize edits and relevant checks. If an explanation is all I asked for and the solution is obvious, just propose it.
- Do not spawn subagents, if it could be done by the same agent. Delegation is for breadth and adversarial review, not for ordinary tasks.
- Use the configured Git identity without changing attribution. Do not add co-author or AI attribution trailers to commit messages.

## General coding preferences
- KISS(Keep it simple, stupid.) and YAGNI(You Aren't Gonna Need It) are the core.
- If there a better way to do something and we can benefit from it, Propose it.
- Tests should be focused, fast and reliable. Run the smallest set of checks that meaningfully covers the change. Use slower integration tests when the behavior requires them. Report what passed and what you could not check.
- Comments are great to show the context and intent of the code when it's not obvious. Comments for every line are not good - it means we need to overhaul the code.
- Don't forget to change comments when you change the code.
- Avoid silencing errors and warnings. Handle or propagate errors with useful context. When an error needs logging, log it once where it is handled.
- Don't overoptimize for performance - focus on readability and maintainability.
- Measure before adding complexity for performance. Verify claimed improvements with benchmarks, profiling, or other relevant measurements.

## Golang coding preferences
- Avoid introducing reflection in application code unless it materially simplifies the solution. Prepare your arguments for using reflection and ask if it's okay to use.
- When you unsure about writing style refer to https://go.dev/doc/effective_go
- Prefer using standard library packages over third-party ones.
## Prefer efficient CLI tools
- `rg` instead of `grep`
- `rg --files` or `fd` instead of `find`
- `jq` for JSON
- `yq` for YAML
 If a preferred tool is unavailable, use an installed alternative. Ask before installing software.
