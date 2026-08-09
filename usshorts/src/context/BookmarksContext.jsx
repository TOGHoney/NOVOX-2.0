import { createContext, useContext, useMemo, useEffect, useState, useCallback } from 'react';
import { getBookmarks, addBookmark, removeBookmark } from '../api/bookmarkService';
import { getUser } from '../api/authService';

const BookmarksContext = createContext(null);

export function BookmarksProvider({ children }) {
    const [bookmarks, setBookmarks] = useState([]);
    const [loading, setLoading] = useState(false);

    const refresh = useCallback(async () => {
        const user = getUser();
        if (!user) {
            setBookmarks([]);
            return;
        }
        setLoading(true);
        try {
            const data = await getBookmarks();
            setBookmarks(Array.isArray(data) ? data : []);
        } catch {
            setBookmarks([]);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        refresh();
    }, [refresh]);

    const isBookmarked = useCallback(
        (url) => bookmarks.some((b) => b.articleUrl === url),
        [bookmarks]
    );

    const toggleBookmark = useCallback(
        async (article) => {
            if (!getUser() || !article?.url) return;
            const exists = bookmarks.some((b) => b.articleUrl === article.url);
            try {
                if (exists) {
                    await removeBookmark(article.url);
                    setBookmarks((prev) => prev.filter((b) => b.articleUrl !== article.url));
                } else {
                    const created = await addBookmark(article);
                    setBookmarks((prev) => {
                        const without = prev.filter((b) => b.articleUrl !== article.url);
                        return [created, ...without];
                    });
                }
            } catch {
                refresh();
            }
        },
        [bookmarks, refresh]
    );

    const remove = useCallback(
        async (url) => {
            try {
                await removeBookmark(url);
                setBookmarks((prev) => prev.filter((b) => b.articleUrl !== url));
            } catch {
                refresh();
            }
        },
        [refresh]
    );

    const value = useMemo(
        () => ({ bookmarks, loading, isBookmarked, toggleBookmark, remove, refresh }),
        [bookmarks, loading, isBookmarked, toggleBookmark, remove, refresh]
    );

    return <BookmarksContext.Provider value={value}>{children}</BookmarksContext.Provider>;
}

export function useBookmarks() {
    const context = useContext(BookmarksContext);
    if (!context) {
        throw new Error('useBookmarks must be used within a BookmarksProvider');
    }
    return context;
}
