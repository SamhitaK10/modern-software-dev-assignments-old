# Deciding what "correct" means

Read this at step 3 of bug-repro-first. The reported output being surprising is not enough.
Walk the sources in order and stop at the first one that settles it.

1. **Docs and types.** README, API docs, JSDoc/type signatures, docstrings. If they describe
   the current behavior, it is intended, however odd. Report "not a bug" and quote them.
2. **Existing tests.** `grep` the tests for the function and for neighbors. A test that
   pins the current output means changing it is a behavior change, not a bug fix: ask first.
3. **Sibling behavior in the same codebase.** Often the best oracle. If `toISOString()`
   already prints a negative value as `-PT1H30M`, then `format()` printing `-1:-30:00`
   for the same value is inconsistent, and the sibling tells you the intended sign convention.
   Search for the same concept implemented elsewhere (`grep` the concept, not the function).
4. **History.** `git log -S'<snippet>' -- <file>` and the linked PR/issue. Use it to learn
   intent, not to decide. A past decision can be wrong, but you should know about it.
5. **Other implementations or specs** (the library this one imitates, an RFC, ISO 8601).
   Useful for a recommendation. Not enough alone to change behavior, because users depend
   on this library's behavior, not the other one's.

## Outcomes

- **Settled by 1-3:** proceed. Name the source in your report.
- **Only 4-5, or nothing:** the bug is a *proposal*. Stop before editing source. Deliver
  the repro and 2 options with consequences (for example "match library X, which changes
  existing output for callers who ...", "leave as is and document"), recommend one, and ask.
- **Several inputs, only some clearly wrong** (for example mixed-sign values): fix only the
  clear region and list the rest as open questions. Do not invent semantics for the gap.

## Smells that you are about to "fix" intended behavior

- The "bug" is the same in the docs' own example output.
- Fixing it needs a changed expectation in an existing test.
- The reporter's expectation comes from a different library and the issue contains no
  repo-specific justification.
