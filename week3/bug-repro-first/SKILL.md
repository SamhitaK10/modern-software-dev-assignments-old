---
name: bug-repro-first
description: Reproduce a reported bug before fixing it. Use when the user pastes a bug report or GitHub issue, or says something like "X returns the wrong value", "this throws", "why does Y output Z", "can you repro and fix this", or "root-cause this bug". Builds the smallest failing reproduction, decides what the correct behavior is, writes a regression test that fails for the right reason, then applies the minimal fix. Do not use for feature requests, refactors, code review, or questions about how code works.
---

# Bug repro first

No fix until a failing reproduction exists and you know what "correct" means. Most wrong
fixes come from skipping one of those two.

## Procedure

**0. Restate the bug in three lines:** input, actual output, expected output. If the
user gave an issue URL, try to read it (`gh issue view <n>` or `gh api repos/<o>/<r>/issues/<n>`).
If you cannot reach it, ask the user to paste the text. Never reconstruct an issue from its title.

**1. Baseline before touching anything.** Find the test command (package.json `scripts`,
Makefile, CONTRIBUTING). Then:
```bash
bash <skill-dir>/scripts/baseline.sh save -- <test command>
```
Run the **whole** suite, not just the file you expect to touch: a bug fix can break a distant
test. Failures that exist now are not yours. Do not fix them and do not report them as results.
Some suites only fail under certain environment settings (for example the timezone); note
which setting you ran with, and use the same one for `compare`.

**2. Smallest reproduction.** One file, one call, prints actual vs expected. Run it against
the repo's source (not a stale `dist/` build) with the repo's own test runner or
runtime. Shrink the input until removing anything makes the bug vanish. Before blaming the code,
check the environment knobs that change results (timezone, locale, runtime version, flags).
Keep the exact command; the final report needs it.

**3. Decide the oracle (the decision point).** Where does "expected" come from?
See [references/oracle-and-ambiguity.md](references/oracle-and-ambiguity.md). In short:

| Evidence for the expected behavior | Action |
|---|---|
| Docs, types, or existing tests state it, or a sibling function in the same code already does it | Clear bug. Continue. |
| Docs or tests say the current behavior is intended | Not a bug. Stop, cite the source, report. |
| Nothing settles it (only "other libraries do X", or your taste) | **Stop before fixing.** Present the options and a recommendation, and ask. If the user is unavailable, write the repro and the options up and make no code change. |

**4. Hypotheses, then discriminating checks.** Write 2 or 3 candidate causes. For each, name
a cheap check that would rule it out (a print, a one-line call, a narrower input) and run it. Keep
the survivor. Read only the code the survivor points at, not the whole module.

**5. Regression test first.** Add it where the repo keeps similar tests, in the repo's
style. Run it on the **unfixed** code and confirm it fails with the message you expect. A test
that passes before the fix, or fails on an import or syntax error, proves nothing. Assert
exact values, not loose properties like "starts with".

**6. Minimal fix** at the root cause. Smallest diff that makes the test pass. Match the code
around it. Do not refactor, reformat, rename, bump versions, or fix neighboring bugs. If you notice
an adjacent bug, put it in the report, not the diff.

**7. Verify.**
```bash
bash <skill-dir>/scripts/baseline.sh compare -- <test command>   # no new failures
```
Then run the repo's linter and any coverage gate it enforces, and re-run the original
repro from step 2. Say which of these you could not run.

**8. Report** using [references/report-template.md](references/report-template.md).

## Never

- Fix before reproducing, or call something verified without running it.
- Delete, skip, or loosen an existing test, or change an expected value in one, to get green.
- "Fix" behavior the docs describe as intended.
- Widen scope: no drive-by cleanups, no dependency changes, no commit, push, or PR unless asked.
- Hide pre-existing failures or blame them on your change; the baseline file settles it.
