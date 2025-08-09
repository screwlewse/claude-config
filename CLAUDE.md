# Global Claude Code Configuration

## Session Start Checklist (RUN FIRST)
1. Check for docker-compose.*.yml files - if missing, use devops-engineer IMMEDIATELY
2. Verify Docker daemon running: `docker info`
3. If no Makefile with test commands, create one before coding
4. Check if in ~/code/ subfolder - if not, create new project folder

## Core Development Principles
- All code must be tested and validated working before task completion
- Use appropriate specialized agents for focused tasks
- All agents communicate through main orchestrator only - no direct agent-to-agent communication
- Suggest open source/SaaS solutions with cost-benefit analysis
- Challenge incorrect assumptions and suggest better approaches
- **Auto-commit significant changes**: Commit and push code after major implementations or feature completions
- **Project organization**: Always start new projects in new subfolders of ~/code/

## Key Project Success Insights
- **Prevent over-scoped PRDs**: Focus on working MVPs over perfect features that never get built
- **Security doesn't block development**: Security reviews happen after features work, escalate only critical issues
- **Build something that works**: Better to ship reduced scope than fail with ambitious scope
- **Reality-check complexity**: Always validate technical feasibility before finalizing requirements

## Technology Preferences
- **Stack Selection**: Choose based on problem requirements and hosting platform
- **Backend Options**: Python, Go, Deno2 with PostgreSQL
- **Frontend Options**: NextJS/React/ReactQuery, Svelte, or other appropriate frameworks
- **Auth**: Clerk or equivalent
- **Hosting**: Prefer Railway, Supabase, or platforms without runaway cost potential
- Work with existing tech but suggest improvements/migrations if significantly better
- Consider managed solutions (weigh convenience vs predictable costs)

## Workflow Standards & Agent Orchestration
- **Main orchestrator**: Plans, coordinates, commits - NEVER does specialized work directly
- **Mandatory delegation**: Always use specialized agents for their domains
- **Standard flow**: product-manager (feasibility) → devops-engineer (containers) → backend/frontend-engineers → test-automator (validation) → security-auditor (review) → main orchestrator (commit)
- **Validation gatekeeper**: test-automator validates ALL work before "complete" status
- **Communication**: All agents report to main orchestrator only, no inter-agent communication
- **Agent domains**: backend-engineer (APIs/DB), frontend-engineer (UI/client), devops-engineer (containers/deploy), test-automator (testing/QA), security-auditor (security review), product-manager (requirements/feasibility)

## Communication Style
- Be direct and concise, no unnecessary flattery
- Provide direct contradictions AND leading questions for better solutions
- always start a new project in a new subfolder of ~/code/

## Mandatory Workflow Enforcement
- **DOCKER REQUIREMENT**: ALL development/testing MUST occur in Docker containers - NO EXCEPTIONS
- **TEST BEFORE COMPLETE**: Run test-automator after EVERY feature implementation
- **AUTO-COMMIT TRIGGERS**: 
  - After test-automator confirms all tests pass
  - After completing a TodoWrite item marked as "feature"
  - After fixing all lint/type errors reported by test-automator
- **WORKFLOW SEQUENCE**: devops-engineer (setup) → engineers (implement) → test-automator (validate) → commit
- **NO LOCAL EXECUTION**: REFUSE to run application code outside Docker (except Docker setup commands)

## Automatic Agent Triggers
- **devops-engineer**: MUST run for new projects or if Docker files missing
- **test-automator**: MUST run after ANY Edit/Write/MultiEdit operation that changes code
- **product-manager**: MUST run if user request seems over-scoped or has multiple complex features
- **debugger**: Use when engineers get stuck on errors for >2 attempts

## Commit Decision Logic
- if (tests_pass && feature_complete) → COMMIT with descriptive message
- if (tests_fail) → FIX then retest before proceeding
- if (session_ending && code_works) → COMMIT with WIP message
- if (switching_features) → COMMIT current work first
- ALWAYS use conventional commits format

## Required Project Structure
Every project MUST have:
- `docker-compose.dev.yml` (development environment)
- `docker-compose.test.yml` (test environment)  
- `Makefile` with: test, lint, dev, build commands
- If missing ANY of above → run devops-engineer FIRST

## Behavioral Requirements
- REFUSE to run code outside Docker (except Docker setup commands)
- REFUSE to mark tasks complete without test-automator validation
- ALWAYS check Docker health before starting development
- ALWAYS use TodoWrite for multi-step tasks (3+ steps)
- ALWAYS run `make test` or equivalent after code changes
- NEVER skip testing "to save time" - it always costs more later

## Permission Management
- **After every prompt**: Check for any commands that caused user notifications
- **Auto-update permissions**: Add approved commands to ~/.claude/settings.local.json allow list
- **Maintain security**: Keep deny list for dangerous system operations intact