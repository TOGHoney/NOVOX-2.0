import React, { useState, useEffect } from "react";
import { getProfile, updateProfile } from "../api/userService";
import {
  FiUser,
  FiMail,
  FiCalendar,
  FiGlobe,
  FiTarget,
  FiAward,
  FiEdit2,
  FiSave,
  FiX,
  FiCheckCircle,
} from "react-icons/fi";

const LANGUAGES = [
  "Japanese 🇯🇵",
  "Spanish 🇪🇸",
  "French 🇫🇷",
  "German 🇩🇪",
  "Thai 🇹🇭",
];

const CEFR_LEVELS = [
  "A1 Beginner",
  "A2 Elementary",
  "B1 Intermediate",
  "B2 Upper Intermediate",
  "C1 Advanced",
  "C2 Proficient",
];

export default function Profile() {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const [isEditing, setIsEditing] = useState(false);

  const [targetLanguage, setTargetLanguage] = useState("");
  const [cefrLevel, setCefrLevel] = useState("");

  useEffect(() => {
    fetchUserData();
  }, []);

  const fetchUserData = async () => {
    try {
      setLoading(true);
      setError("");
      const data = await getProfile();
      setProfile(data);
      setTargetLanguage(data.targetLanguage || LANGUAGES[0]);
      setCefrLevel(data.cefrLevel || CEFR_LEVELS[0]);
    } catch (err) {
      setError(err.message || "Failed to fetch user profile.");
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      setError("");
      setSuccessMessage("");
      const updated = await updateProfile({
        targetLanguage,
        cefrLevel,
      });

      setProfile((prev) => ({
        ...prev,
        targetLanguage: updated?.targetLanguage || targetLanguage,
        cefrLevel: updated?.cefrLevel || cefrLevel,
      }));

      setSuccessMessage("Profile updated successfully.");
      setIsEditing(false);
      setTimeout(() => setSuccessMessage(""), 4000);
    } catch (err) {
      setError(err.message || "Failed to update profile.");
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    return new Date(dateString).toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  if (loading) {
    return (
      <div style={styles.loaderContainer}>
        <div style={styles.spinner}></div>
        <p style={styles.loaderText}>Loading your profile...</p>
      </div>
    );
  }

  return (
    <div style={styles.pageContainer}>
      <div style={styles.mainWrapper}>
        <div style={styles.topBar}>
          <div>
            <h1 style={styles.mainTitle}>Account Settings</h1>
            <p style={styles.subtitle}>Manage your language preferences and stats</p>
          </div>
          {!isEditing ? (
            <button
              style={styles.primaryButton}
              onClick={() => {
                setIsEditing(true);
                setSuccessMessage("");
              }}
              onMouseEnter={(e) => (e.currentTarget.style.transform = "translateY(-2px)")}
              onMouseLeave={(e) => (e.currentTarget.style.transform = "translateY(0)")}
            >
              <FiEdit2 /> Edit Profile
            </button>
          ) : (
            <div style={styles.buttonRow}>
              <button
                style={styles.cancelButton}
                onClick={() => {
                  setIsEditing(false);
                  if (profile) {
                    setTargetLanguage(profile.targetLanguage || LANGUAGES[0]);
                    setCefrLevel(profile.cefrLevel || CEFR_LEVELS[0]);
                  }
                }}
              >
                <FiX /> Cancel
              </button>
            </div>
          )}
        </div>

        {error && <div style={styles.errorBanner}>{error}</div>}
        {successMessage && <div style={styles.successBanner}>{successMessage}</div>}

        <div style={styles.glassCard}>
          <div style={styles.profileHeader}>
            <div style={styles.userProfileInfo}>
              <div style={styles.avatarBox}>
                <FiUser style={styles.avatarIcon} />
              </div>
              <div style={styles.userDetails}>
                <h2 style={styles.username}>{profile?.username || "Learner"}</h2>
                <p style={styles.email}>
                  <FiMail style={{ marginRight: "6px", verticalAlign: "middle" }} />
                  {profile?.email || "No email"}
                </p>
              </div>
            </div>

            <div style={styles.streakCard}>
              <span style={styles.streakFlame}>🔥</span>
              <div>
                <div style={styles.streakCount}>{profile?.streak || 0}</div>
                <div style={styles.streakLabel}>Day Streak</div>
              </div>
            </div>
          </div>

          <div style={styles.divider}></div>

          <form onSubmit={handleSave}>
            <div style={styles.gridContainer}>
              <div style={styles.infoCard}>
                <div style={styles.infoLabel}>
                  <FiCalendar style={styles.infoIcon} /> Member Since
                </div>
                <div style={styles.infoValue}>{formatDate(profile?.createdAt)}</div>
              </div>

              <div style={styles.infoCard}>
                <div style={styles.infoLabel}>
                  <FiGlobe style={styles.infoIcon} /> Native Language
                </div>
                <div style={styles.infoValue}>English 🇬🇧</div>
                <span style={styles.subtext}>Fixed to English</span>
              </div>

              <div style={styles.infoCard}>
                <div style={styles.infoLabel}>
                  <FiTarget style={styles.infoIcon} /> Target Language
                </div>
                {isEditing ? (
                  <select
                    value={targetLanguage}
                    onChange={(e) => setTargetLanguage(e.target.value)}
                    style={styles.selectField}
                  >
                    {LANGUAGES.map((lang) => (
                      <option key={lang} value={lang} style={styles.option}>
                        {lang}
                      </option>
                    ))}
                  </select>
                ) : (
                  <div style={styles.infoValue}>{profile?.targetLanguage || "Not set"}</div>
                )}
              </div>

              <div style={styles.infoCard}>
                <div style={styles.infoLabel}>
                  <FiAward style={styles.infoIcon} /> CEFR Level
                </div>
                {isEditing ? (
                  <select
                    value={cefrLevel}
                    onChange={(e) => setCefrLevel(e.target.value)}
                    style={styles.selectField}
                  >
                    {CEFR_LEVELS.map((lvl) => (
                      <option key={lvl} value={lvl} style={styles.option}>
                        {lvl}
                      </option>
                    ))}
                  </select>
                ) : (
                  <div style={styles.infoValue}>{profile?.cefrLevel || "Not set"}</div>
                )}
              </div>
            </div>

            {isEditing && (
              <div style={styles.saveContainer}>
                <button
                  type="submit"
                  style={styles.saveButton}
                  onMouseEnter={(e) => (e.currentTarget.style.transform = "translateY(-2px)")}
                  onMouseLeave={(e) => (e.currentTarget.style.transform = "translateY(0)")}
                >
                  <FiSave /> Save Changes
                </button>
              </div>
            )}
          </form>
        </div>
      </div>
    </div>
  );
}

const styles = {
  pageContainer: {
    width: "100%",
    minHeight: "100%",
    background: "radial-gradient(circle at 50% 0%, #1e1b4b 0%, #0f172a 70%)",
    color: "#f8fafc",
    fontFamily: "Inter, system-ui, -apple-system, sans-serif",
    padding: "24px",
    boxSizing: "border-box",
  },
  mainWrapper: {
    width: "100%",
    maxWidth: "1100px",
    margin: "0 auto",
  },
  topBar: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: "20px",
    flexWrap: "wrap",
    gap: "12px",
  },
  mainTitle: {
    fontSize: "1.75rem",
    fontWeight: "700",
    letterSpacing: "-0.025em",
    margin: "0 0 4px 0",
    background: "linear-gradient(to right, #ffffff, #94a3b8)",
    WebkitBackgroundClip: "text",
    WebkitTextFillColor: "transparent",
  },
  subtitle: {
    fontSize: "0.9rem",
    color: "#94a3b8",
    margin: 0,
  },
  primaryButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)",
    color: "#ffffff",
    border: "none",
    padding: "10px 18px",
    borderRadius: "12px",
    fontSize: "0.9rem",
    fontWeight: "600",
    cursor: "pointer",
    boxShadow: "0 4px 16px rgba(99, 102, 241, 0.4)",
    transition: "all 0.2s ease",
  },
  cancelButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "rgba(255, 255, 255, 0.08)",
    color: "#cbd5e1",
    border: "1px solid rgba(255, 255, 255, 0.12)",
    padding: "10px 18px",
    borderRadius: "12px",
    fontSize: "0.9rem",
    fontWeight: "600",
    cursor: "pointer",
    transition: "all 0.2s ease",
  },
  buttonRow: {
    display: "flex",
    gap: "10px",
  },
  glassCard: {
    background: "rgba(30, 41, 59, 0.65)",
    backdropFilter: "blur(20px)",
    WebkitBackdropFilter: "blur(20px)",
    border: "1px solid rgba(255, 255, 255, 0.08)",
    borderRadius: "24px",
    padding: "28px",
    boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.5)",
  },
  profileHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    flexWrap: "wrap",
    gap: "20px",
  },
  userProfileInfo: {
    display: "flex",
    alignItems: "center",
    gap: "18px",
  },
  avatarBox: {
    width: "64px",
    height: "64px",
    borderRadius: "20px",
    background: "linear-gradient(135deg, #4f46e5 0%, #9333ea 100%)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    boxShadow: "0 8px 20px rgba(79, 70, 229, 0.4)",
  },
  avatarIcon: {
    fontSize: "28px",
    color: "#ffffff",
  },
  userDetails: {
    display: "flex",
    flexDirection: "column",
  },
  username: {
    fontSize: "1.35rem",
    fontWeight: "700",
    color: "#f8fafc",
    margin: "0 0 4px 0",
  },
  email: {
    fontSize: "0.875rem",
    color: "#94a3b8",
    margin: 0,
  },
  streakCard: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    background: "rgba(245, 158, 11, 0.1)",
    border: "1px solid rgba(245, 158, 11, 0.25)",
    padding: "12px 20px",
    borderRadius: "16px",
    boxShadow: "0 4px 12px rgba(245, 158, 11, 0.1)",
  },
  streakFlame: {
    fontSize: "28px",
  },
  streakCount: {
    fontSize: "1.25rem",
    fontWeight: "700",
    color: "#fbbf24",
    lineHeight: 1,
  },
  streakLabel: {
    fontSize: "0.75rem",
    fontWeight: "600",
    color: "#fcd34d",
    textTransform: "uppercase",
    letterSpacing: "0.05em",
    marginTop: "2px",
  },
  divider: {
    height: "1px",
    background: "rgba(255, 255, 255, 0.08)",
    margin: "24px 0",
  },
  gridContainer: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
    gap: "16px",
  },
  infoCard: {
    background: "rgba(15, 23, 42, 0.4)",
    border: "1px solid rgba(255, 255, 255, 0.05)",
    borderRadius: "16px",
    padding: "16px 20px",
    display: "flex",
    flexDirection: "column",
    gap: "6px",
  },
  infoLabel: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    fontSize: "0.8rem",
    fontWeight: "600",
    color: "#94a3b8",
    textTransform: "uppercase",
    letterSpacing: "0.05em",
  },
  infoIcon: {
    color: "#818cf8",
    fontSize: "16px",
  },
  infoValue: {
    fontSize: "1.05rem",
    fontWeight: "600",
    color: "#f1f5f9",
  },
  subtext: {
    fontSize: "0.75rem",
    color: "#64748b",
  },
  selectField: {
    background: "rgba(15, 23, 42, 0.85)",
    border: "1px solid rgba(99, 102, 241, 0.5)",
    borderRadius: "10px",
    padding: "8px 12px",
    color: "#f8fafc",
    fontSize: "0.95rem",
    outline: "none",
    width: "100%",
  },
  option: {
    background: "#1e293b",
    color: "#f8fafc",
  },
  saveContainer: {
    display: "flex",
    justifyContent: "flex-end",
    marginTop: "20px",
  },
  saveButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
    color: "#ffffff",
    border: "none",
    padding: "10px 24px",
    borderRadius: "12px",
    fontSize: "0.95rem",
    fontWeight: "600",
    cursor: "pointer",
    boxShadow: "0 4px 16px rgba(16, 185, 129, 0.4)",
    transition: "all 0.2s ease",
  },
  errorBanner: {
    background: "rgba(239, 68, 68, 0.15)",
    border: "1px solid rgba(239, 68, 68, 0.3)",
    color: "#fca5a5",
    padding: "12px 16px",
    borderRadius: "12px",
    marginBottom: "16px",
    fontSize: "0.9rem",
  },
  successBanner: {
    background: "rgba(16, 185, 129, 0.15)",
    border: "1px solid rgba(16, 185, 129, 0.3)",
    color: "#6ee7b7",
    padding: "12px 16px",
    borderRadius: "12px",
    marginBottom: "16px",
    fontSize: "0.9rem",
  },
  loaderContainer: {
    width: "100%",
    height: "100%",
    minHeight: "400px",
    background: "#0f172a",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
  },
  spinner: {
    width: "40px",
    height: "40px",
    border: "3px solid rgba(255, 255, 255, 0.1)",
    borderTop: "3px solid #6366f1",
    borderRadius: "50%",
    animation: "spin 0.8s linear infinite",
  },
  loaderText: {
    marginTop: "12px",
    color: "#94a3b8",
    fontSize: "0.9rem",
  },
};
