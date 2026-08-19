import React, { useState } from 'react';
import { login } from '../api/authService';
import {useNavigate} from 'react-router-dom';

const Login = () => {
    const [formData, setFormData] = useState({ email: '', password: '' });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate=useNavigate();

    const onChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const onSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const user=await login(formData);
            if(user.profileCompleted){
                navigate('/');
            }else{
                navigate('/learning-profile');
            }
        } catch (err) {
            setError(err.response?.data?.message || 'Invalid email or password.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-page">
            <div className="auth-card">
                <p className="auth-logo">NOVOX</p>
                <h2 className="auth-title">Welcome back</h2>
                <p className="auth-subtitle">
                    Don't have an account?{' '}
                    <a onClick={() => navigate('/signup')}>Create one</a>
                </p>

                <form className="auth-form" onSubmit={onSubmit}>
                    {error && <div className="auth-error">{error}</div>}

                    <div className="auth-field">
                        <label>Email</label>
                        <input
                            name="email"
                            type="email"
                            required
                            onChange={onChange}
                            className="auth-input"
                            placeholder="you@example.com"
                        />
                    </div>

                    <div className="auth-field">
                        <label>Password</label>
                        <input
                            name="password"
                            type="password"
                            minLength={6}
                            required
                            onChange={onChange}
                            className="auth-input"
                            placeholder="Enter your password"
                        />
                    </div>

                    <button type="submit" className="auth-submit" disabled={loading}>
                        {loading ? 'Signing in...' : 'Sign In'}
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

export default Login;
