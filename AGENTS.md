# GODOT Infinite Runner (AI Assisted)

## Godot objects must be subscenes

For every Godot task, create each distinct game object as a self-contained,
reusable `.tscn` scene and instance that scene into levels or other parent
scenes. This applies to both 2D and 3D objects, even when only one instance
is currently needed. Do not assemble an object's node hierarchy directly
inside a level or generate that hierarchy only in a level script.

- Give the scene a descriptive object name and an appropriate root node.
- Keep all nodes needed by the object inside its scene, including visuals,
  collision shapes and physics bodies, interaction areas, animation, audio,
  and object-specific scripts, as applicable. Supporting nodes do not each
  need their own scene; they belong to the object they implement.
- Reuse or update an existing object scene when one already exists. Put
  shared behavior and appearance in that scene; use exported properties
  and instance transforms for per-instance configuration.
- Spawn objects dynamically by instantiating their `PackedScene` rather
  than reconstructing their nodes in code.
- When changing an existing object embedded in a level, extract that
  object's hierarchy into a subscene as part of the change, preserving its
  behavior, transforms, and connections. Leave unrelated objects alone.

For example, adding a barrel means creating `barrel.tscn` with a `Barrel`
root and all required 2D or 3D visual, collision, and behavior nodes, then
placing instances of `barrel.tscn` in the level.

## 3D model workflow: Blender MCP and Godot MCP

For every task that creates, edits, imports, or fixes 3D models, meshes,
materials, rigs, or animations for this project:

1. Check live MCP connectivity before choosing an implementation path.
   Discover the available Blender and Godot tools; tool availability or a
   running application process alone does not prove a live connection.
   For Blender, call `get_addon_status` and `get_scene_info`. For Godot,
   call `godot_editor_read` with `get_state` and verify that the connected
   editor is using the intended project before making changes.
2. When Blender is running and connected, use Blender MCP for model
   inspection, authoring, editing, and export. Python executed through
   Blender MCP is allowed. Do not silently substitute a separate headless
   Blender process or another modeling workflow when the live connection
   works. Inspect the existing scene first and preserve unrelated objects
   and unsaved user work. After edits, inspect the scene and a viewport
   screenshot to verify the result.
3. Validate changed assets in Godot through Godot MCP when connected.
   Import or refresh the exported asset, open the relevant project scene
   (or a focused test scene), and run it in the engine. Check applicable
   scale, orientation, materials, visibility, animation, and collision
   behavior. Use runtime/spatial data for state checks and a game screenshot
   for visual checks. Check editor import errors and available game runtime
   errors separately; editor logs alone do not prove the game is error-free.
   Run `godot_validate_meshes` after procedural mesh changes or when geometry
   renders incorrectly without reported errors, before tuning lighting.
4. If an MCP connection is unavailable, report the failed check and the
   specific connection requirement. Continue independent work and use an
   appropriate available fallback, but identify that fallback explicitly.
   Never claim Blender MCP was used or Godot engine validation passed unless
   it actually happened. Report any remaining engine validation as incomplete.
5. In the final response, briefly state which MCPs were used, what was
   tested in Godot, and any remaining validation gaps. Apply this workflow
   to any delegated model work as well. An explicit user instruction for
   the current task may override this default workflow.

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
