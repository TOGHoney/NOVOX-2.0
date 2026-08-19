const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },

    targetLanguage: { type: String},
    nativeLanguage: { type: String, default: "English"},
    cefrLevel: { type: String},
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    
    profileCompleted: {type: Boolean, default: false},
    streak: {type: Number, default: 0}
}, { timestamps: true });

// Change to a regular function expression to ensure 'this' and 'next' work
userSchema.pre('save', async function() {
    if (!this.isModified('password')) {
        return;
    }
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);

});

module.exports = mongoose.model('User', userSchema);