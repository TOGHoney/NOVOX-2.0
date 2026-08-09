import { FiBookmark } from 'react-icons/fi';
import { useBookmarks } from '../context/BookmarksContext';

export default function BookmarkButton({ article, style, size = 14 }) {
    const { isBookmarked, toggleBookmark } = useBookmarks();
    const saved = Boolean(article?.url) && isBookmarked(article.url);

    return (
        <button
            onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                toggleBookmark(article);
            }}
            title={saved ? 'Remove bookmark' : 'Save article'}
            style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                background: saved ? '#1e293b' : '#f1f5f9',
                color: saved ? '#fff' : '#0f172a',
                border: '1px solid #cbd5e1',
                padding: '0.35rem 0.7rem',
                borderRadius: '6px',
                fontWeight: 600,
                fontSize: '0.75rem',
                cursor: 'pointer',
                ...style,
            }}
        >
            <FiBookmark size={size} fill={saved ? 'currentColor' : 'none'} />
            {saved ? 'Saved' : 'Save'}
        </button>
    );
}
