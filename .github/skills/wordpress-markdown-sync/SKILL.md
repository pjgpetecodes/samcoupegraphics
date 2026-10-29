---
name: wordpress-markdown-sync
description: Use when importing WordPress post edits into markdown, preparing a WordPress block export, updating blog links/media, or reconciling the repository's blog post files.
---

# WordPress and markdown synchronization

## Identify the matching post first

- Read the article title, step/file names, and emulator disk IDs from the HTML.
- Compare them with the markdown drafts. Do not assume `blogN` in an HTML
  filename means its content is for the same-numbered markdown; exports can be
  stale or copied between folders.
- Do not overwrite markdown from an export that does not describe that article.

## Import WordPress updates

- Preserve the WordPress HTML byte-for-byte unless the user has asked for an
  export update. Hash before and after if this is an explicit constraint.
- `wp_sync.mjs <md> <html> --dry` previews block-level synchronization, but
  refuses when block counts differ and depends on a matching sync baseline.
  Check the dry-run output for pushes/conflicts; do not treat it as a general
  importer or allow markdown-to-HTML pushes during an import-only task.
- `wp_to_md.mjs <html> <temp.md>` can import supported blocks. Run it to a
  temporary file first, then compare carefully before applying: confirm headings,
  prose, lists, tables, images, code language, emulator IDs, and assembly paths.
  Do not replace the draft wholesale if the importer drops or rewrites content.
- Keep real uploaded image URLs and the actual gist/assembly file paths. Flag
  WordPress-only text or unsupported block types for deliberate handling.

## Update a WordPress export

- Only update/regenerate HTML if the user explicitly asks in the current task.
- Confirm the draft and export actually correspond, then back up the current
  HTML. Render using:

  ```powershell
  node md_to_wordpress.mjs <blog-post.md> <blog-post-wordpress.html> --force
  ```

- Check that generated prior-post links resolve through `PRIOR_POSTS` in
  `md_to_wordpress.mjs`; verify gist IDs and emulator disk IDs in the output.
- Never publish or upload the result unless separately requested.
