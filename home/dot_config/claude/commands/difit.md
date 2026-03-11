Show git diff from branch point with difit (including uncommitted changes, excluding unmerged main changes).

Wait for the browser to close and capture review comments.

```bash
cd <the directory of target repository>
difit . origin/master
```

Run with `timeout: 600000` (10 minutes max) to wait for browser close.
If review takes longer, use `run_in_background: true` and check output with TaskOutput.
