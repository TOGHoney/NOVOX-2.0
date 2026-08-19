import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signup } from '../api/authService';

const Signup = () => {
    const [formData, setFormData] = useState({
        username: '',
        email: '',
        password: '',
    });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const { username, email, password } = formData;

    const onChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const onSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await signup({ username, email, password });
            navigate('/learning-profile');
        } catch (err) {
            console.log(err.response);
            console.log(err.response?.data);
            setError(err.response?.data?.message || 'An error occurred during signup.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-page">
            <div className="auth-card">
                <p className="auth-logo">NOVOX</p>
                <h2 className="auth-title">Create your account</h2>
                <p className="auth-subtitle">
                    Already have an account?{' '}
                    <a onClick={() => navigate('/login')}>Sign in</a>
                </p>

                <form className="auth-form" onSubmit={onSubmit}>
                    {error && <div className="auth-error">{error}</div>}

                    <div className="auth-field">
                        <label htmlFor="username">Username</label>
                        <input
                            id="username"
                            name="username"
                            type="text"
                            required
                            value={username}
                            onChange={onChange}
                            className="auth-input"
                            placeholder="Choose a username"
                        />
                    </div>

                    <div className="auth-field">
                        <label htmlFor="email">Email address</label>
                        <input
                            id="email"
                            name="email"
                            type="email"
                            autoComplete="email"
                            required
                            value={email}
                            onChange={onChange}
                            className="auth-input"
                            placeholder="you@example.com"
                        />
                    </div>

                    <div className="auth-field">
                        <label htmlFor="password">Password</label>
                        <input
                            id="password"
                            name="password"
                            type="password"
                            autoComplete="new-password"
                            minLength={6}
                            required
                            value={password}
                            onChange={onChange}
                            className="auth-input"
                            placeholder="Create a secure password"
                        />
                        <p className="auth-hint">Must be at least 6 characters.</p>
                    </div>

                    <button type="submit" className="auth-submit" disabled={loading}>
                        {loading ? 'Creating account...' : 'Sign Up'}
                    </button>
                </form>

                <div className="auth-divider">Or continue with</div>

                <div className="auth-socials">
                    <button className="auth-social-btn" type="button">
                        <img src="https://www.svgrepo.com/show/475656/google-color.svg" alt="Google" />
                    </button>
                    <button className="auth-social-btn" type="button">
                        <img src="https://www.svgrepo.com/show/475647/github-color.svg" alt="GitHub" />
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Signup;
