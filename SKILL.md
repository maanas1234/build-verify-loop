---
name: build-verify-loop
description: Build verification loop for every change in swayu-app. Use after any code, schema, skill file or test edit, and before saying something works or asking to commit. The builder never judges its own work: deterministic checks first, then a separate verifier, then for outcome copy or pictures a quality judge against references. Stops after 3 rounds.
---

# Build verify loop

Rule one: the agent that built the change never decides that it is ready.
Ready for review needs two things: the checks pass, and a separate verifier says YES.
A YES is not Swayu's Done. See the last section.

## Before you build

Write the done condition in one or two lines.
Say what the owner will see when it works, and which test proves it.
Run that test first and watch it fail. A test that passes before the change proves nothing.

For a change to what an outcome says, the proving test includes one where a made up fact (a feature, number or claim the owner never gave) is stopped. Every claim must come from the owner's own details.

If the change touches a path named in CODEOWNERS, stop before building. Write what you found in the General questions table and wait for Harish's go.

## The loop, at most 3 rounds

A round is one pass from Build to the verifier. Fixing a failed check inside a round is fine; going back to Build after a NO starts the next round.

1. **Build.** Make the smallest change that meets the done condition.
2. **Check.** Run `~/.claude/skills/build-verify-loop/verify.sh` from inside swayu-app. Do not run the checks by hand or skip one. It runs, in order and stopping at the first failure:
   - typecheck
   - lint on the changed files
   - the contracts check if you touched `contracts/`
   - every test that touches a changed file

   It prints one line, `VERDICT PASS` or `VERDICT FAIL <step>`, and saves the failing log in `/tmp/verify-bundle/`. Quote that line in your report.
   - Add `--branch` to check everything the branch changed.
   - Before a pull request: run `scripts/bring-current.sh`, then `pnpm check` in full. Both must pass.
3. **On a failure:** read the actual error output. Fix the cause. Go back to step 2. At most 3 fixes per round; if the checks still fail, stop and report.
   - Never weaken, skip or delete a test to get green.
   - Never mark a failure as known on your own. Only your engineer does that, with a reason, and only after it is shown to fail on main too.
4. **On a pass: separate verifier.** Start a fresh subagent that has not seen your reasoning. It only reads code and runs checks; it never edits a file, commits or writes anywhere. If your engineer or Harish has not yet allowed a separate reviewer for this job, ask first.
   - Give it the done condition, the `git diff` and the check output. Do not give it your conclusion.
   - Tell it to try to break the change, not to confirm it.
   - It returns exactly one verdict, then its findings. Each finding names the file, the line and a concrete case that fails.
     - `YES`: ready for review.
     - `NO`: each finding becomes the next round, back to step 1.
     - `MAYBE`: name what cannot be checked locally, and tell your engineer. This is not done.
5. **Hard stop.** After 3 rounds without YES, stop. Tell your engineer what still fails and where the output is. Do not keep going.

## Outcome quality (words and pictures)

Tests prove the shape of an outcome, not whether it is good.
For any change to what an outcome writes or draws, add a quality loop on real model runs.

1. **Agree the goal first.** Ask your engineer one high level question before writing any rules: what should the finished output look like, and what makes it good for the owner? Keep it high level, not rule by rule.
2. **Draft the rubric and references.** From that answer, draft 6 to 8 numbered rules a good marketing manager would apply (for example "says what the buyer gets first", "no hype the owner did not give"), 3 to 5 examples marked good or bad with one line on why, and one sample of the finished output.
3. **Ask for approval.** Show the draft to your engineer and ask what they think. Change it until they say yes. The agent never judges against rules no person has approved; until then, label every result "judged against draft rules".
4. **Calibrate the judge first.** Show it one clearly bad and one clearly good page. If it does not say NO to the bad one, fix the rubric before you trust it.
5. **Run real businesses.** At least 3 different businesses, real model, real outcome steps. Real runs cost money: before each batch, tell your engineer roughly how many model calls it will make and get an OK.
6. **Code checks facts, the judge checks quality.** The judge is a separate model call, ideally a different model from the writer. It sees the rubric, the references, the owner's inputs, the saved business profile and the finished page the owner will see. It never sees the writer's reasoning.
7. **Verdict per page:** YES, NO or MAYBE. Each finding gives the rule, the exact words, a fix, and a severity:
   - `must`: the owner would change it before using the page. Only these make a NO.
   - `nice`: a taste preference. Listed, never blocking.
   Ask for at most 3 findings, most important first. Without severity the judge says NO to everything.
8. **Fixes never add facts.** A fix may only reorder, cut or rephrase what the owner gave. A judge left free will suggest new details, and code that checks numbers will not catch a made up phrase.
9. **Rework.** Send only the must findings back to the writer, together with its last draft. Tell it to change only what is named and keep every feature. A fresh rewrite drops good parts. At most 2 reworks, then stop and show the owner the round with the fewest must findings.
10. **Measure.** Record how often the judge says NO and the tokens it costs. A couple of loops is enough. Balance quality against cost.

## Report to your engineer

- The round count.
- The check result, with the real output.
- The verifier's verdict and findings.
- For outcomes: how many businesses passed the judge, after how many reworks, and the token cost.

Never say "working" for anything that has not had a real run.

## Commits and pushes

Ask your engineer before every commit and before every push. Show the real check output when you ask. Never commit to main, never force push, never use `--no-verify`.

## YES is not Done

A YES from this loop means ready for review. Swayu's Done also needs:
- The owner flow works on staging.
- Harish has seen it screen by screen.
- Another engineer has reproduced it once.
- The failure and interruption cases on the outcome page were tried.
- The pull request carries regression tests, and the version is recorded.
