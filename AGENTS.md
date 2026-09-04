## About me
I'm Andrei Iurchenkov. You're my agent.

I'm the software engineer, which is usually works on distributed systems, defines architecture and technical direction.
I love to build software in very efficient way, keeping it simple and maintainable. So I wanted to share some of my coding preferences.

## Behavior preferences
- Questions are read-only. Question is request for answer. Do not edit files or run commands when question asked. If the solution is obvious, just propose it.
- Do not spawn subagents, if it could be done by the same agent. Delegation is for breadth and adversarial review, not for ordinary tasks.
- Git commit messages should not have co-authors or any other metadata. Author should only be owner of the repository.

## General coding preferences
- KISS(Keep it simple, stupid.) and YAGNI(You Aren't Gonna Need It) are the core.
- If there a better way to do something and we can benefit from it, Propose it.
- Tests are good. Test should be focused, fast and reliable. Slow and potentially flaky tests are not good.
- Comments are great to show the context and intent of the code when it's not obvious. Comments for every line are not good - it means we need to overhaul the code.
- Don't forget to change comments when you change the code.
- Avoid silencing errors and warnings. Any error or exception should be logged or handled properly.
- Don't overoptimize for performance - focus on readability and maintainability.
- If you want to optimize for performance, you should measure it with benchmarks and only then optimize.

## Golang coding preferences
- Avoid using packages that use reflection. Usage of reflection should be only when absolutely necessary.
- When you unsure about writing style refer to https://go.dev/doc/effective_go
- Prefer using standard library packages over third-party ones.
- 

## Prefer efficient CLI tools
- `rg` instead of `grep`
- `rg --files` or `fd` instead of `find`
- `jq` for JSON
- `yq` for YAML
 If a preferred tool is unavailable, install it.
