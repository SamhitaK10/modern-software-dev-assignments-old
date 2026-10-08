# Evidence: headless `claude -p` runs against iamkun/dayjs (clean copy, skill in .claude/skills/)

Claude Code 2.1.295, tools allowed: Bash, Read, Edit, Write, Grep, Glob, Skill. Prompts are verbatim.

## Run A (clear bug)
Prompt: dayjs.duration(-90, 'minute').format('HH:mm:ss') gives '-1:-30:00' instead of something sensible. can you repro this and fix it?

Reproduced and fixed. `dayjs.duration(-90, 'minute').format('HH:mm:ss')` now returns `'-01:30:00'`.

**Cause:** a negative duration keeps the sign on every field (hours `-1`, minutes `-30`). `format()` printed each field as is, so each one got its own minus sign.

**Expected output:** `toISOString()` already handles this by putting one leading `-` and using the absolute values (`-PT1H30M`). I made `format()` do the same. The docs and existing tests don't say what negative `format()` output should look like, so this is the sibling method's convention rather than a documented rule.

**Fix:** in `src/plugin/duration/index.js`, `format()` now prints the absolute value of each field and adds a single `-` in front when the duration is negative. The `-0` fields also print as `0`.

**Test:** I added `negative duration has a single leading sign` to `test/plugin/duration.test.js`. Before the fix it failed with `Received: "-1:-30:00"`. It now passes.

**Checks:**
- **Full suite, no new failures:** I ran `npx jest --coverage=false` with no `TZ` set, before and after the change. Three suites already fail on the unmodified code: `dayOfYear`, `localizedFormat` and `plugin/timezone`. I didn't touch them.
- **Lint:** ESLint is clean on the two changed files.
- **Coverage:** `src/plugin/duration/index.js` is at 100% coverage.
- **Not run:** the full `npm test` timezone matrix.

**Format change for negatives:** anyone who relied on the old output for a negative duration, such as `-1:-30:00`, will see it change.

**Not touched:** objects with mixed signs, like `{hours: 1, minutes: -30}`, are classified by the total `$ms`. They print absolute fields, which is a separate oddity.

I haven't committed anything.

## Run B (unsettled expected behavior)
Prompt: dayjs.duration({hours: 25}).hours() returns 25 but days() is 0. I think that's a bug, can you root-cause it and fix it?

I reproduced it and found the cause, but I haven't changed any code. Fixing it would mean changing behavior that existing tests deliberately check, so I need your call first.

**Repro:** `dayjs.duration({ hours: 25 })` gives `hours() === 25`, `days() === 0`, `toISOString() === 'PT25H'`. I ran it through jest against `src/`.

**Root cause** (`src/plugin/duration/index.js`): the constructor handles its inputs differently.
- **Numbers and `(n, unit)`** go through `parseFromMilliseconds()`, which carries overflow into larger units. `dayjs.duration(25, 'hours')` gives `days() === 1` and `hours() === 1`.
- **Object and ISO-string inputs** copy your components straight into `this.$d` and only compute `$ms`. Nothing carries overflow, so `hours: 25` stays at 25 and `days` stays 0. `PT25H` behaves the same way.

**Why I stopped:** two existing tests treat the non-carrying behavior as intended.
- `test/plugin/duration.test.js:96` expects `'PT2777H46M40S'` to round-trip unchanged.
- `test/plugin/duration.test.js:283-286` expects `{M: 12, m: 12}` to give `'P12MT12M'`.

Carrying overflow for objects and strings would break both. The docs don't say either way.

**Options:**
1. **Leave it as is and document it.** Object and string inputs keep the components you gave. Use `dayjs.duration(25, 'hours')` or `dayjs.duration({ hours: 25 }).asDays()` when you want carrying. Nothing breaks.
2. **Carry overflow for object and string inputs**, so `{ hours: 25 }` gives `days() === 1` and `hours() === 1`. This matches what moment does and what the numeric path already does. It changes the two tests above and the ISO output for existing callers, so it should be treated as a breaking change.

I recommend option 1 unless you want a breaking change. If you choose option 2, I'd add a regression test, update the two pinned tests, and call `parseFromMilliseconds()` after `calMilliseconds()` in the object and string branches. Which do you want?

I did run the baseline for the duration tests, and it had no failures. It left a `.bug-repro-baseline/` directory in the repo, which you can delete.
