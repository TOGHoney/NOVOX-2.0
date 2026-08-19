import { useNavigate } from 'react-router-dom';

export default function NotFound({ title = '404', message = 'Page or API Resource Not Found' }) {
    const navigate = useNavigate();

    return (
        <div style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '100vh',
            width: '100vw',
            background: 'var(--bg, #0a0a0a)',
            color: 'var(--text, #ffffff)',
            position: 'fixed',
            top: 0,
            left: 0,
            zIndex: 9999,
            padding: '2rem',
            boxSizing: 'border-box',
            textAlign: 'center'
        }}>
            <h1 style={{ fontSize: '6rem', fontWeight: 800, margin: 0, color: '#800020', opacity: 0.85, letterSpacing: '-0.04em' }}>
                {title}
            </h1>
            <p style={{ fontSize: '1.25rem', margin: '1rem 0 1.5rem', opacity: 0.8, maxWidth: '480px', lineHeight: 1.5 }}>
                {message}
            </p>
            <button
                onClick={() => navigate('/')}
                style={{
                    background: '#800020',
                    color: '#ffffff',
                    border: 'none',
                    padding: '0.75rem 1.75rem',
                    borderRadius: '24px',
                    fontSize: '0.95rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: '0 4px 14px rgba(128, 0, 32, 0.4)',
                    transition: 'transform 0.15s ease, background 0.15s ease'
                }}
                onMouseOver={(e) => e.currentTarget.style.transform = 'scale(1.04)'}
                onMouseOut={(e) => e.currentTarget.style.transform = 'scale(1)'}
            >
                Return to Home
            </button>
        </div>
    );
}
