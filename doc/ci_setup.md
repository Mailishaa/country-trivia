# CI Setup — OpenCode Automated PR Review

This repo reviews every pull request automatically using the OpenCode CLI with
the **Big Pickle** model (`opencode/big-pickle`) and posts the result as a PR
comment.

| File | Purpose |
|------|---------|
| `.github/workflows/pr-review.yml` | The CI workflow |
| `.opencode/agents/pr-reviewer.md` | Read-only review agent definition |
| `doc/ci_setup.md` | This guide |

---

## 1. Create an OpenCode API key

Big Pickle is served by **OpenCode Console**, so you need a Console API key.

1. Sign in at <https://opencode.ai/console>.
2. Add billing details and credits. Big Pickle is currently **free**, but
   Console still requires a payment method on the account before it will issue
   a working key.
3. Open the **API Keys** page and create a key, for example `country-trivia-ci`.
4. Copy the key. You only get to see it once.

> Big Pickle is a "stealth model" offered free for a limited time, and during
> that period OpenCode states that collected data may be used to improve the
> model. Do not review pull requests containing secrets or confidential code
> until that changes. See the Privacy section of the
> [Console models docs](https://opencode.ai/v2/docs/console/models/).

---

## 2. Add the key to the repository

Add it as an **Actions secret** named `OPENCODE_API_KEY`.

### Option A — GitHub UI

1. Go to <https://github.com/Mailishaa/country-trivia/settings/secrets/actions>
2. Click **New repository secret**.
3. Name: `OPENCODE_API_KEY`
4. Secret: paste the key from step 1.
5. Click **Add secret**.

### Option B — `gh` CLI

```bash
gh secret set OPENCODE_API_KEY --repo Mailishaa/country-trivia
```

It prompts for the value. Paste the key and press enter.

### Option C — OpenCode CLI login on your machine

To test locally before wiring up CI, authenticate the same way:

```bash
opencode auth login opencode --method api-key
```

---

## 3. Optional: change the model

The model defaults to `opencode/big-pickle`. To change it without editing the
workflow, add an Actions **variable** named `OPENCODE_REVIEW_MODEL`:

<https://github.com/Mailishaa/country-trivia/settings/actions/variables>

For example, set it to `opencode/space-bunny-free` or `opencode/glm-5.3-flash`
to review with a paid or zero-retention model instead.

---

## 4. Test it

The workflow only runs on pull request events, so open one:

```bash
git checkout -b ci/test-review
echo "# ci smoke test" >> README.md
git commit -am "test: trigger automated review"
git push -u origin ci/test-review

gh pr create --base develop --title "test: trigger automated review" --body "Checking that the OpenCode review workflow runs."
```

Then watch it:

```bash
gh run watch
```

You should see the **Auto-review** job run, followed by an OpenCode review
comment on the PR. Close the PR afterwards.

To run the same review locally:

```bash
export OPENCODE_API_KEY="your-key-here"
opencode run \
  --standalone \
  --agent pr-reviewer \
  --model opencode/big-pickle \
  "Review the changes on this branch against develop."
```

Keep `--standalone` here too. It is what makes the private server pick up
`OPENCODE_API_KEY`; without it the CLI may fall back to a shared background
service that has no credentials, which fails with the "free tier" error below.

Confirm the key is picked up before relying on CI:

```bash
opencode auth list
```

`opencode` should appear as an authenticated integration. If it lists nothing,
the key never reached OpenCode.

---

## 5. How the workflow behaves

### Triggers

`pull_request` events for `opened`, `synchronize`, `reopened`, and
`ready_for_review` — so a review lands as soon as a PR is raised, and updates
on every subsequent push.

### Concurrency

Grouped per PR with `cancel-in-progress: true`. Pushing a new commit cancels an
in-flight review, so a PR never accumulates stale reviews.

### Comments are updated, not stacked

The comment carries the hidden marker `<!-- opencode-pr-review -->`. The
workflow looks for an existing comment with that marker and patches it. Each PR
therefore keeps exactly one review comment that always reflects the latest push.

### The review is strictly read-only

`.opencode/agents/pr-reviewer.md` denies `edit`, `shell`, `webfetch`, and
`websearch`, and allows only `read`, `glob`, `grep`, and `list`. This matters
for security: the workflow checks out the pull request's own code, so a
malicious branch could otherwise get its code executed by a shell tool. The
agent is also told never to claim it ran a test or linter.

The diff is passed in with `--file` rather than letting the agent run
`git diff`, which keeps it bounded and deterministic. Diffs over 120,000
characters are truncated with a visible note.

### Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
```

The workflow gets read access to the code and write access only to PR comments.
It cannot push commits, create releases, or modify repository settings.

---

## 6. Known limitations

**Pull requests from forks cannot be reviewed.** GitHub does not expose
repository secrets to `pull_request` runs originating from a fork, so
`OPENCODE_API_KEY` is empty and the job fails at the verification step. This
affects public outside contributors, not your own branches.

Options if you need fork PRs reviewed:

- Run the review from a maintainer branch instead of the contributor's.
- Switch the trigger to `pull_request_target`. **Read the warning first:** that
  event runs with repository secrets and write scope in the context of the base
  repository, so checking out and running fork-controlled code becomes an RCE
  risk. Only do this with the read-only agent and no shell access.
- Use a separate bot account or GitHub App that is allowed to run untrusted
  code.

**The model can still be wrong.** Big Pickle is a free, limited-time model.
Treat its output as a first pass for a human reviewer, not as an approval gate.
For stricter enforcement, require the review to be present before merging —
though as above, that check is unreliable for fork PRs.

**Console requires a payment method.** Even for a free model, the key will not
work without billing details on the account.

---

## 7. Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `Error from provider (Console): OpenCode's free tier can only be used from within OpenCode` | The CLI fell back to the anonymous free tier because **no key was found**. Almost always means `OPENCODE_API_KEY` is not reaching the step. Confirm the secret name is exact and that the step's `env:` block maps it — `opencode run` only forwards the key when it is set in the step environment. |
| `The OPENCODE_API_KEY repository secret is not set` | The secret is missing or named differently. It must be an **Actions secret** named exactly `OPENCODE_API_KEY`. |
| `opencode run failed` in the step log | Usually a bad or expired key. Check the Console API Keys page, then rotate the secret. |
| `The model returned an empty review` | The model call produced no output. Check `opencode-review-logs` artifact for `review.log`. |
| `No model is available for session` | `OPENCODE_REVIEW_MODEL` is misspelled, or that model is disabled for the workspace. Verify with `curl https://opencode.ai/zen/v1/models`. |
| Job hangs until the 20-minute timeout | The runner has no outbound network access, or the model is rate limited. |
| Workflow does not trigger at all | `pull_request` runs the workflow **from the PR's own head branch**, so a workflow added in a PR does run for that PR. It only starts applying to *other* PRs once merged into the base branch. Also confirm the YAML is under `.github/workflows/` and that Actions are enabled for the repo. |

Download the raw output for any run with:

```bash
gh run download --repo Mailishaa/country-trivia
```

---

## 8. Disabling the review

Edit `.github/workflows/pr-review.yml` and remove `on: pull_request`, or delete
the file. Nothing else in the project depends on it.
