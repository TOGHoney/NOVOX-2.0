const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');


const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

const validateSignupInput = ({ username, email, password }) => {
    if (!username || !email || !password) {
        return 'All fields are required';
    }
    if (typeof username !== 'string' || username.trim().length < 3) {
        return 'Username must be at least 3 characters long';
    }
    if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        return 'Please provide a valid email address';
    }
    if (typeof password !== 'string' || password.length < 6) {
        return 'Password must be at least 6 characters long';
    }
    return null;
};

exports.signup = async (req, res) => {
    const { username, email, password } = req.body;
    const validationError = validateSignupInput({ username, email, password });
    if (validationError) {
        return res.status(400).json({ message: validationError });
    }

    try {
        const user = await User.create({ username: username.trim(), email: email.toLowerCase(), password });
        res.status(201).json({ 
            _id: user._id, 
            username: user.username,
            email: user.email,
            role: user.role,
            nativeLanguage: user.nativeLanguage,
            targetLanguage: user.targetLanguage,
            cefrLevel: user.cefrLevel,
            profileCompleted: user.profileCompleted,
            streak: user.streak,
            token: generateToken(user._id) 
        });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ message: 'Email or username already in use' });
        }
        console.error("Signup Error Details:", error);
        res.status(400).json({ message: 'Error creating user' });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    if (user && (await bcrypt.compare(password, user.password))) {
        res.json({
            _id: user._id,
            username: user.username,
            email: user.email,
            role: user.role,
            nativeLanguage: user.nativeLanguage,
            targetLanguage: user.targetLanguage,
            cefrLevel: user.cefrLevel,
            profileCompleted: user.profileCompleted,
            streak: user.streak,
            token: generateToken(user._id)
        });
    } else {
        res.status(401).json({ message: 'Invalid credentials' });
    }
};