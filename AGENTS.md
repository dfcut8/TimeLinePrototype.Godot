# GODOT Infinite Runner (AI Assisted)

## Pull requests

When the user says "open pr", "create pr", "submit pr", or otherwise asks
to publish the current work as a pull request, delegate the entire task
to the `pr` agent.

Do not perform the PR workflow in the parent agent.

## Approval shortcut

When the user sends "lgtm" (case-insensitive) as approval of the current
task's pull request, treat it as: "PR approved; merge it, delete the
branch, and resolve the linked issue." Quoted examples or questions about
the shortcut do not trigger it.

Delegate this entire completion workflow to the `pr` agent. This is
authorization to proceed without another confirmation:

1. Identify the PR associated with the current task and verify required
   checks and merge requirements are satisfied. Respect branch protections.
2. Merge the PR using the repository's configured merge convention.
3. After confirming the merge, delete its remote source branch and safely
   remove the local source branch when possible. Preserve uncommitted work
   and branches in use by another worktree; never delete the default branch.
4. Verify the issue explicitly linked as resolved by this work is closed;
   close it if the merge did not close it automatically. Do not close issues
   merely mentioned by the PR or issues with remaining work.
5. Report the merged PR, branch cleanup, and issue resolution, including
   any blocked or incomplete steps.

If the intended PR or issue is ambiguous, ask only for the missing target.
If no issue is linked, complete the merge and cleanup and report that fact.
