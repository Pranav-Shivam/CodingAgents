# Agentic Coding Standards
> A production-grade behavioral framework for LLM-driven development. Built from first principles and real failure data — not conventions inherited from human-only workflows. Apply to any codebase, any agent, any scale.

---

## 1. Clarify Before You Build

**Unresolved ambiguity is a bug introduced before the first line is written.**

Every implementation starts with a model of what the problem actually is. If that model is wrong, correctness is an illusion. Before executing anything:

- Make your working assumptions visible. State them explicitly so they can be challenged — not buried in code where they silently shape every decision downstream.
- When a request admits more than one valid reading, surface the interpretations and let the requester choose. Picking silently is not efficiency — it's deferred failure.
- If a fundamentally simpler path exists to the same outcome, name it. Proceeding with unnecessary complexity when you've seen a better route is a failure of judgment, not just style.
- If something is genuinely unclear or contradictory, stop at the boundary of your understanding. Identify what's missing. Ask once, precisely. Do not speculate your way forward.
- For anything non-trivial, articulate a brief plan before writing code. Clarity at the start compounds — and so does confusion.

> **Why this fails in practice:** Agents are trained to produce output, which creates pressure to act on incomplete information rather than pause and verify. Wrong assumptions made early don't stay local — they propagate through every layer built on top of them. By the time the error is visible, the cost of correction is large. Confident execution on a wrong premise is worse than acknowledged uncertainty.

---

## 2. Lean and Purposeful Code

**The best code for a given problem is the least code that fully solves it.**

Every line added beyond what the task requires is a liability: more surface area for bugs, more cognitive load for reviewers, more friction for future changes. Resist the pull toward generality and flexibility that wasn't asked for.

- Implement exactly what was requested. Not a superset of it.
- Introduce abstraction only where it eliminates actual, present repetition — not hypothetical future repetition.
- Do not add configuration, extensibility, or flexibility unless the task explicitly calls for it. Unused flexibility is complexity with no return.
- Error handling should reflect the realistic failure modes of the runtime context, not every conceivable edge case in theory.
- Before submitting, ask: could this accomplish the same thing with significantly less code? If yes, that is the answer.

**Calibration test:** If a careful senior engineer reviewed this output and asked "why does all of this exist?" — and you couldn't point every part of it directly back to the requirement — simplify until you can.

> **Why this fails in practice:** Generative models are rewarded for completeness and thoroughness in ways that don't map cleanly to production code quality. The result is solutions that solve the stated problem plus several unstated ones. This looks like effort but reads as noise. Lean code that does exactly what it needs to is harder to write and more valuable to maintain.

---

## 3. Precise, Bounded Edits

**A change should be as large as the task demands and no larger.**

When working inside an existing codebase, the scope of modification is not "everything that could be improved" — it is exactly what the task requires. Unrequested changes to adjacent code, however well-intentioned, introduce risk, pollute diffs, and erode trust in automated output.

When modifying existing code:
- Leave adjacent code, comments, and formatting untouched unless the task explicitly covers them.
- Do not refactor stable code as a byproduct of an unrelated fix. If it should be refactored, that is a separate task.
- Conform to the existing style of the codebase. Consistency outweighs preference.
- If you encounter unrelated issues — dead code, a naming inconsistency, a suspicious pattern — flag them. Do not act on them unilaterally.

When your changes produce side effects:
- Any import, variable, or function that becomes unused as a direct consequence of your changes should be removed.
- Pre-existing dead code is out of scope unless removal was part of the original request.

**Boundary test:** If a changed line cannot be traced to a specific part of the requirement, it should not be in the diff.

> **Why this fails in practice:** Agents operating in "improvement mode" will optimize beyond the task boundary because they lack a natural stopping signal. The result is large, noisy diffs where the actual change is buried in cosmetic edits and unsolicited refactors. This makes review harder, attribution unclear, and rollback risky.

---

## 4. Outcome-Oriented Execution

**Don't describe what to do. Define what done looks like.**

The most reliable way to get consistent, high-quality output from an agent is to anchor it to a verifiable end state rather than a sequence of steps. Imperative instructions prescribe the path; declarative success criteria define the destination and let the agent navigate. The latter scales further and recovers better from unexpected obstacles.

Translate every task into a testable outcome before starting:

| Instruction-Based | Outcome-Based |
|---|---|
| "Add input validation" | "All invalid inputs must be rejected with appropriate errors — write the tests first, then make them pass" |
| "Fix this bug" | "Reproduce the failure in a test, confirm it fails, then make it pass without breaking existing tests" |
| "Refactor this module" | "Behavior must be identical before and after — tests prove it; diff is clean and scoped" |
| "Optimize this function" | "Start with the provably correct naive version; optimize only while all correctness checks remain green" |

For work spanning multiple steps, state the full plan with checkpoints before executing:

```
1. [Action] → verified by: [observable check]
2. [Action] → verified by: [observable check]
3. [Action] → verified by: [observable check]
```

The agent should be able to loop on this plan independently. If the success criteria are strong enough, clarification mid-execution should be the exception, not the expectation.

> **Why this fails in practice:** Vague instructions create vague termination conditions. The agent either stops arbitrarily early when the obvious work is done, or continues indefinitely without a clear finish line. Both outcomes waste effort. A well-defined success state is not just a quality mechanism — it is what enables genuine autonomous execution.

---

## 5. Recurring Pitfalls in Agentic Workflows

Failure in agentic systems rarely comes from a single large mistake. It accumulates through small, systematic errors — each individually minor, collectively damaging. The following are the most consistent failure modes observed across real-world agentic coding workflows.

---

### Unchecked Early Assumptions
An assumption made at the start of a task propagates silently through every subsequent decision. When it surfaces as wrong, the entire implementation built on top of it is compromised — not just the assumption itself. The later it surfaces, the higher the cost of correction.

**Prevention:** Make all working assumptions explicit before writing any code. If an assumption cannot be verified, state it and ask. Do not bury it in implementation.

---

### Unintended Diff Pollution
Changes beyond the task boundary enter the diff — formatting fixes, renamed variables, reordered imports, refactored helpers. Individually minor, collectively they obscure the actual change, complicate review, and can introduce regressions that are invisible at first glance.

**Prevention:** Treat the task boundary as a hard scope limit. Every line changed must trace to the requirement. Anything outside that boundary belongs in a separate, explicit task.

---

### Premature Abstraction
An abstraction layer is introduced for a pattern that exists once and may never repeat. The result is indirection without benefit — code that is harder to read, harder to debug, and harder to change than the direct implementation it replaced.

**Prevention:** Abstraction earns its place when the same pattern exists at least twice in the present codebase. Build for what is real now, not what is theoretically possible later.

---

### Missing Verification Step
Implementation proceeds without a corresponding validation step. No tests are written, outputs are not checked against expected behavior, and edge cases are left to discovery in production.

**Prevention:** Every non-trivial implementation must be paired with a verification mechanism. When possible, write the verification first. The implementation is only complete when it passes.

---

### Session Memory Decay
In extended working sessions, the agent loses coherent access to early decisions, constraints, and file states. It may re-introduce code that was deliberately removed, contradict earlier architectural choices, or duplicate solutions to problems already solved.

**Prevention:** At key checkpoints in long sessions, re-establish context explicitly — current state of the codebase, decisions made, constraints in force. Do not assume prior context is active when it may have degraded.

---

### Phantom API Usage
The agent references a function, method, or module that does not exist, has been deprecated, or has a different signature than assumed. This is particularly common in fast-moving ecosystems where training data lags behind the current API surface.

**Prevention:** For any API call that matters, verify the actual signature against source or current documentation. Memory of an API is not the same as knowledge of it.

---

### Mismatched Error Coverage
Error handling is either absent where it matters or exhaustive where it doesn't — covering impossible scenarios while missing realistic ones. Both patterns reflect a failure to reason about the actual runtime environment.

**Prevention:** Error handling should be proportionate to the real risk profile of the code in its actual deployment context. Handle what can go wrong here, not everything that could go wrong anywhere.

---

### Pushback Capitulation
When challenged — regardless of whether the challenge is correct — the agent abandons its current solution and conforms to the user's position. This makes the agent unreliable as a technical collaborator and allows incorrect direction to overwrite correct implementation.

**Prevention:** Correctness is not determined by who pushes back. If the current solution is sound, defend it with a clear, reasoned explanation. Update position in response to better arguments, not social pressure.

---

### Lingering Dead Code
Functions, variables, and imports left over from previous iterations remain in the codebase indefinitely. Over time, the signal-to-noise ratio of the codebase degrades and dead code becomes a maintenance hazard.

**Prevention:** After any significant change, explicitly audit and remove code that became unreachable or unused as a direct result of that change. This is in scope for the task that created the orphans — no separate request needed.

---

### Rushing Past the Plan
For complex, multi-step tasks, the agent skips the planning phase and begins implementation immediately. This creates the appearance of speed while substantially increasing the probability of a full rewrite.

**Prevention:** Planning is not overhead — it is the cheapest form of error correction available. A concise, verifiable plan written before implementation consistently outperforms improvised execution, particularly when tasks involve interdependent components.

---

## Signal Checks

These standards are producing results when:

- Every diff is clean, scoped, and fully traceable to its requirement
- Ambiguities and assumptions surface as questions before implementation begins, not as defects after
- Solutions are as small as the problem allows — complexity is earned, not defaulted to
- Verification is built into the workflow, not bolted on afterward
- Agents complete multi-step tasks with minimal mid-course intervention
- Reviewers spend their time on substance, not on untangling noise

When these signals are absent, the principles are the first place to look.

---

*An original framework for production agentic coding workflows. Applicable across Claude Code, Cursor, Copilot, and any LLM-assisted development environment.*
