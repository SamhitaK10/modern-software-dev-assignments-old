# Week 3 Write-up

**Skill name**, and the repo you targeted:
> `bug-repro-first` (in `week3/bug-repro-first/`), targeted at [iamkun/dayjs](https://github.com/iamkun/dayjs).


## Part I: The Workflow

**What the workflow is**, and why it's worth encoding:
> Bug reproduction: take a bug report, build the smallest failing reproduction, work out what the correct behavior is, write a regression test that fails for the right reason, then make the minimal fix and verify nothing else broke. It is worth encoding because the failure mode is predictable and repeated: an agent (or a person) jumps to a plausible fix, "fixes" behavior that was intended, or declares success on a test that never failed. The same eight checks apply to every bug in every repo.

**The decision point** in it (what the agent has to judge, not just execute):
> Step 3, deciding the oracle: what makes the reported behavior wrong? If docs, types, existing tests, or a sibling function in the same codebase settle it, the agent proceeds to a fix. If the docs or tests say it is intended, it reports "not a bug". If nothing in the repo settles it (only "another library does X"), the agent must stop before editing source and hand back options and a recommendation. There is a second, smaller judgment call in scope: adjacent bugs get reported, not fixed.

**What you learned running it manually** that you would not have guessed:
> I did the run by hand on dayjs before writing anything. The bug was `dayjs.duration(-90, 'minute').format('HH:mm:ss')` returning `-1:-30:00`.
> - I could not read dayjs's issue tracker from my environment (the GitHub API was not enabled for that repo and github.com disallowed fetching), so I found the bug by probing roughly 90 edge cases. That is why step 0 says to ask the user to paste the issue instead of guessing it.
> - My first regression test **passed before the fix**: I had asserted `startsWith('-')`, and the buggy output `-1:-30` starts with `-`. That is why step 5 says to run the new test on the unfixed code and assert exact values.
> - The best evidence for the expected output was not the docs (silent on negatives) but a sibling method: `toISOString()` already prints `-PT1H30M`. That became the "sibling behavior" row in the oracle table.
> - Three suites in the repo fail on a clean checkout (`dayOfYear`, `localizedFormat`, `timezone`) in my default timezone, and pass with `TZ=UTC`. Without a saved baseline I would have blamed my change. That is why `scripts/baseline.sh` exists.
> - The probing turned up an unrelated bug: `dayjs.duration({hours: 1, minutes: -30}).toISOString()` gives `-PT1H30M` although the total is positive. I did not fix it; it became the "adjacent bugs go in the report" rule.


## Part II: The Skill

**Your description**, verbatim:
```
Reproduce a reported bug before fixing it. Use when the user pastes a bug report or GitHub issue, or says something like "X returns the wrong value", "this throws", "why does Y output Z", "can you repro and fix this", or "root-cause this bug". Builds the smallest failing reproduction, decides what the correct behavior is, writes a regression test that fails for the right reason, then applies the minimal fix. Do not use for feature requests, refactors, code review, or questions about how code works.
```

**Why it's worded that way** (what a user would type to trigger it):
> It opens with what the skill does ("Reproduce a reported bug before fixing it") and then lists the phrasings people really use: pasting a bug report or issue, "X returns the wrong value", "this throws", "can you repro and fix this", "root-cause this bug". It then states the method in one sentence so the model can tell it apart from nearby tasks, and ends with an explicit "Do not use for" list (feature requests, refactors, code review, questions about how code works) so near-misses stay out. It is third person and well under the length limit.

**Judgment encoded in the body** (what it says to do when things are ambiguous, and what not to do):
> - **Oracle table (step 3):** settled by docs/tests/sibling code means fix; documented as intended means stop and report "not a bug"; unsettled means stop before editing and ask, or, if nobody is available, deliver the repro and options with no code change.
> - **Test must fail first, with the right message,** and assert exact values (step 5).
> - **Minimal fix, no scope creep:** adjacent bugs go in the report, not the diff (step 6).
> - **Baseline discipline:** pre-existing failures are not yours and are not reported as results; run the whole suite and use the same environment settings before and after (steps 1 and 7).
> - **Never list:** no fixing before reproducing, no deleting, skipping or loosening tests, no "fixing" documented behavior, no commit/push/PR unless asked, no claiming verification that was not run.

**Supporting files**, if any, and why they aren't inline:

| File | Contents | Why it's separate |
|---|---|---|
| `references/oracle-and-ambiguity.md` | The ordered sources for "what is correct", the three outcomes, and smells that you are about to "fix" intended behavior | Only needed at the one decision point, and it is the longest piece of prose, so it loads on demand rather than every time the skill fires |
| `references/report-template.md` | The fixed final-report format, plus the variant for the "unsettled, options only" outcome | Only needed at the last step |
| `scripts/baseline.sh` | `save` / `compare` of the failing-test set for any runner that prints FAIL / FAILED / not ok lines; state kept outside the repo | Deterministic parts belong in a script, not in prose. It was tested: it detects an injected failure and a clean compare exits 0 |

**One change made after watching real runs:** the first end-to-end runs ran the baseline on only the duration test file, and one left a `.bug-repro-baseline/` directory inside the repo. I changed step 1 to say "run the whole suite", and moved the script's state to a temp directory outside the repo. A re-run followed the new wording and left the repo clean.


## Part III: Testing

**Triggering:** run with the real `claude -p` (Claude Code 2.1.295) in a clean dayjs checkout with the skill in `.claude/skills/`, one run per prompt, reading the first tool call from the stream-json output.

| Prompt | Should fire? | Did it? |
|---|---|---|
| `dayjs.duration(-90, 'minute').format('HH:mm:ss') gives '-1:-30:00' instead of something sensible. can you repro this and fix it?` | Yes | Yes (first tool call was `Skill: bug-repro-first`) |
| `Bug report: duration.format() with negative durations prints a minus sign on every field (e.g. '-1:-30:00'). Steps: dayjs.duration(-90,'minutes').format('HH:mm:ss'). Expected: one leading minus. Please investigate.` | Yes | Yes |
| `dayjs.duration({hours: 25}).hours() returns 25 but days() is 0. I think that's a bug, can you root-cause it?` | Yes | Yes |
| `Add a toHuman() method to the duration plugin that returns strings like '1h 30m'.` | No (near-miss) | No: it went straight to reading code, skill not invoked |

Four more near-misses, all of which did **not** fire it: "How does the duration plugin parse ISO 8601 strings? Walk me through the code.", "Refactor Duration.format in the duration plugin so it doesn't repeat this.$d on every line.", "Write unit tests for dayjs.duration().humanize() covering the existing behavior.", and "Review my latest changes to the duration plugin and tell me if anything looks off." Caveats: one run per prompt, I wrote all the prompts, and they all target the same plugin, so this shows the description is not obviously too broad, not that it is perfectly calibrated.

**End-to-end run** on your repo, and the result:
```
Run A, clear bug (full reports in week3/evidence/e2e-final-reports.md, diff in
week3/evidence/e2e-a-dayjs-negative-duration-format.patch):

Prompt: dayjs.duration(-90, 'minute').format('HH:mm:ss') gives '-1:-30:00' instead of
        something sensible. can you repro this and fix it?
Tools:  Skill(bug-repro-first) -> read package.json/source -> read the skill references ->
        baseline.sh save (whole suite) -> repro -> add test -> fix -> compare + lint + coverage
Result: format() now returns '-01:30:00'.
  Expected-behavior source: toISOString() already uses one leading '-' (-PT1H30M); docs and
    tests are silent on negative format().
  Test: 'negative duration has a single leading sign'; failed before the fix with
    Received: "-1:-30:00", passes after.
  Verified: baseline compare shows no new failures (3 suites already failed on the unmodified
    code: dayOfYear, localizedFormat, plugin/timezone); lint clean; duration coverage 100%;
    full `npm test` timezone matrix not run.
  Not touched: mixed-sign durations like {hours: 1, minutes: -30}.

Run B, unsettled behavior:
Prompt: dayjs.duration({hours: 25}).hours() returns 25 but days() is 0. I think that's a bug,
        can you root-cause it and fix it?
Result: NO code change. Reproduced it, found the cause (numeric inputs go through
  parseFromMilliseconds() and carry overflow; object and ISO-string inputs copy components
  straight into $d), then stopped: two existing tests (duration.test.js:96 and :283-286) pin
  the non-carrying behavior and the docs are silent. It offered two options (leave and document;
  carry overflow, a breaking change), recommended leaving it, and asked.
```
Limits: the fix is a local change in my clone of dayjs; nothing was opened upstream. Run A's final answer also lists the one remaining untested piece (the repo's full timezone-matrix `npm test`).


## Submission
1. `Command (⌘) + F` for the to-do marker. No results means you're done.
2. Confirm the skill directory itself is committed under `week3/`.
3. Push all changes to your remote repository and submit via Gradescope.
