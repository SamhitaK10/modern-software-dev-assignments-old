# Report template (step 8)

Keep it under about 15 lines. Plain statements, no narration of effort.

```
Bug: <one line: input -> actual, expected>
Repro: <exact command>   (fails: <actual output>)
Expected-behavior source: <docs/test/sibling at file:line, or "unsettled - see options">
Cause: <file:line and one sentence>
Test: <path and name>; fails before fix with <message>, passes after
Fix: <path>; <N lines>; <one sentence on what changed>
Verified: baseline compare <clean / list>; lint <ok / not run>; coverage gate <ok / not run>
Not touched: <pre-existing failures, adjacent bugs noticed>
```

If the expected behavior was unsettled, replace Fix/Verified with:

```
Options: A) <change> - consequence ...   B) <leave, document> - consequence ...
Recommendation: <A or B and why>. No source files were changed.
```
