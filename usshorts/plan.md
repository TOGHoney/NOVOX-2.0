# LinguaBrief — Comments & Bookmarks

Persistent, per-article comments (visible to every user) plus a per-user bookmark feature, with bookmarks surfaced in the Progress tab.

## Requirements
- Comments are stored in MongoDB, keyed by article URL, attributed to the logged-in author.
- **Every user can read all comments** on an article (public read). Posting/replying/deleting requires login; delete is owner-only.
- Bookmark button on the **Articles page only** (feed cards + full reader toolbar).
- Bookmarks section as a **panel inside the Progress dashboard grid**.

## Backend

1. `models/Comment.js` (new)
   - `articleUrl` (string, required, indexed)
   - `user` (ObjectId ref `User`, required)
   - `text` (string, required)
   - `isReply` (bool, default false), `parent` (ObjectId ref `Comment`, default null)
   - `timestamps`

2. `controllers/commentController.js` (new)
   - `getComments(articleUrl)` — public; sorted oldest→newest; populate `user.username`
   - `createComment` — auth; validates text; supports optional `parentId`
   - `deleteComment` — auth; owner (or admin) only

3. `routes/commentRoutes.js` (new)
   - `GET /api/comments?articleUrl=...` (public)
   - `POST /api/comments` (auth)
   - `DELETE /api/comments/:id` (auth)

4. `models/Bookmark.js` (new)
   - `user` (ObjectId ref `User`, indexed)
   - `articleUrl` (string, required)
   - `article` snapshot: `{ title, description, content, imageUrl, url, source, publishedAt, category, aiSummary }`
   - unique index `{ user: 1, articleUrl: 1 }`
   - `timestamps`

5. `controllers/bookmarkController.js` (new)
   - `getBookmarks` — auth; user's bookmarks, newest first
   - `addBookmark` — auth; upsert by `(user, articleUrl)`; stores article snapshot
   - `removeBookmark` — auth; delete by `(user, articleUrl)`

6. `routes/bookmarkRoutes.js` (new)
   - `GET /api/bookmarks` (auth)
   - `POST /api/bookmarks` (auth)
   - `DELETE /api/bookmarks?articleUrl=...` (auth)

7. `app.js` — mount `/api/comments` and `/api/bookmarks`.

## Frontend

8. `api/commentService.js` (new) — `fetchComments(articleUrl)`, `postComment(articleUrl, text, parentId?)`, `deleteComment(id)`. Uses `client` (auto-attaches JWT).
9. `api/bookmarkService.js` (new) — `getBookmarks()`, `addBookmark(article)`, `removeBookmark(articleUrl)`. Uses `client`.
10. `context/BookmarksContext.jsx` (new) — loads user's bookmarks on mount; exposes `bookmarks`, `isBookmarked(url)`, `toggleBookmark(article)`, `removeBookmark(url)`.
11. `components/BookmarkButton.jsx` (new) — `FiBookmark` filled/outline toggle.
12. `components/CommentSidebar.jsx` — refactor to accept `articleUrl`; fetch comments on open; post via API (author = logged-in username); delete own comments; keep existing markdown-formatting UI.
13. `pages/Articles.jsx` — add `BookmarkButton` to feed cards and full-reader toolbar; pass `activeArticle.url` to `CommentSidebar`.
14. `App.jsx` — wrap app in `BookmarksProvider`.
15. `components/DashboardPanel.jsx` — add a **Bookmarks** panel to the dashboard grid (title/source/date, remove button, empty state).

## Notes
- Article `url` is the stable key (feed `id` is an index only).
- No `User` model changes; bookmarks/comments live in their own collections.
- `GET /api/comments` is public so every user sees the full thread.
