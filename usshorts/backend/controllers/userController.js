const User = require("../models/user");

// GET /api/users/profile
exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user).select("-password");

        if (!user) {
            return res.status(404).json({
                message: "User not found",
            });
        }

        res.status(200).json(user);

    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Server Error",
        });
    }
};


// PUT /api/users/profile
exports.updateProfile = async (req, res) => {
    try {

        const { targetLanguage, cefrLevel, nativeLanguage, profileCompleted } = req.body;

        const user = await User.findById(req.user);

        if (!user) {
            return res.status(404).json({
                message: "User not found",
            });
        }

        if (targetLanguage) {
            user.targetLanguage = targetLanguage;
        }

        if (cefrLevel) {
            user.cefrLevel = cefrLevel;
        }

        // Native language is permanently fixed to English
        user.nativeLanguage = "English";

        if (profileCompleted !== undefined) {
            user.profileCompleted = profileCompleted;
        }

        const updatedUser = await user.save();

        res.status(200).json({
            _id: updatedUser._id,
            username: updatedUser.username,
            email: updatedUser.email,
            nativeLanguage: updatedUser.nativeLanguage,
            targetLanguage: updatedUser.targetLanguage,
            cefrLevel: updatedUser.cefrLevel,
            profileCompleted: updatedUser.profileCompleted,
            streak: updatedUser.streak,
            createdAt: updatedUser.createdAt,
            updatedAt: updatedUser.updatedAt,
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Server Error",
        });
    }
};