# LinguaBrief — Persistent Topic-Based Infinite Feed

Replace the broken infinite feed (which endlessly repeats the same 20 articles) with a persistent, database-backed article pipeline that fetches 100 articles per topic from NewsAPI, stores them for 7 days, and serves them in a round-robin interleaved feed.

## Problem
- `Articles.jsx` calls `fetchHeadlines(category, page)` but the page param is silently dropped
- Backend always fetches `pageSize=20` with no pagination support
- Every "load more" re-fetches the same 20 articles → infinite duplicates
- Articles are never persisted — no database model exists

## Solution
1. Create `Article` MongoDB model with 7-day TTL auto-cleanup
2. Backend fetcher pulls 100 articles per topic from NewsAPI (11 topics, 11 API calls)
3. Cron runs fetcher every 6 hours; also runs on server startup
4. New `/api/feed` endpoint serves round-robin interleaved articles by topic
5. Gemini summaries generated on-demand when user clicks "Read Summary" (saves API quota)
6. Frontend consumes new feed endpoint with proper offset-based infinite scroll

## Topics & NewsAPI Mapping
| Topic | Endpoint | Parameter |
|---|---|---|
| Technology | everything | q=technology |
| Movies | everything | q=movies |
| USA | everything | q=USA |
| India | everything | q=India |
| Japan | everything | q=Japan |
| China | everything | q=China |
| Russia | everything | q=Russia |
| Sports | top-headlines | category=sports&country=us |
| Education | everything | q=education |
| Politics | everything | q=politics |
| Foreign Relations | everything | q=foreign+relations |

## Backend

### 1. `models/Article.js` (new)
- Schema: title, description, content, source, url (unique), imageUrl, publishedAt, topic, aiSummary (nullable), fetchedAt
- TTL index on `fetchedAt` with `expireAfterSeconds: 604800` (7 days)
- Index on `{ topic: 1, fetchedAt: -1 }`

### 2. `services/articleFetcher.js` (new)
- Fetch 100 articles per topic from NewsAPI in parallel
- Normalize and upsert into Article collection (dedup by URL)
- Skip Gemini summaries (lazy-loaded on demand)

### 3. `controllers/feedController.js` (new)
- `GET /api/feed?offset=0&limit=20&topic=...` — round-robin interleaved feed
- `POST /api/feed/summary` — generate Gemini summary for article(s) on demand

### 4. `routes/feedRoutes.js` (new)
- `GET /` → getFeed
- `POST /summary` → fetchSummaries

### 5. `app.js` — mount `/api/feed`
### 6. `server.js` — add node-cron schedule + startup fetch
### 7. `npm install node-cron` in backend

## Frontend

### 8. `api/feedService.js` (new)
- `fetchFeed(offset, limit, topic)` → GET /api/feed
- `fetchSummaries(articleIds)` → POST /api/feed/summary

### 9. `utils/articleUtils.js` — update CATEGORIES to 11 new topics

### 10. `pages/Articles.jsx` — rewrite
- Replace broken page-based fetch with offset-based feed
- Lazy summary loading via API call
- Proper infinite scroll with hasMore from server response

## Display Flow
1. Open Articles → GET /api/feed?offset=0&limit=20 → 20 interleaved articles
2. Scroll → GET /api/feed?offset=20&limit=20 → next 20 appended
3. Click "Read Summary" → POST /api/feed/summary → Gemini generates summary on demand
4. Offset exceeds total → hasMore=false → feed ends naturally
5. Behind the scenes: cron refreshes every 6 hours, TTL auto-deletes >7 day articles
