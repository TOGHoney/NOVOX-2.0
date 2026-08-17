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
    minHeight: "100vh",
    background: "var(--bg, #ffffff)", // Matches global background
    color: "#111111",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    padding: "24px",
    boxSizing: "border-box",
  },
  mainWrapper: {
    width: "100%",
    maxWidth: "1000px",
    margin: "0 auto",
  },
  topBar: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: "24px",
    flexWrap: "wrap",
    gap: "12px",
  },
  mainTitle: {
    fontSize: "1.75rem",
    fontWeight: "800",
    letterSpacing: "-0.02em",
    margin: "0 0 4px 0",
    color: "#111111", // Solid clean text instead of gradient
  },
  subtitle: {
    fontSize: "0.9rem",
    color: "#767676",
    margin: 0,
    fontWeight: "600",
  },
  primaryButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "var(--primary, #800020)", // Uses global accent color
    color: "#ffffff",
    border: "none",
    padding: "10px 20px",
    borderRadius: "24px", // Matches global pill border-radius
    fontSize: "0.9rem",
    fontWeight: "700",
    cursor: "pointer",
    transition: "all 0.15s ease",
  },
  cancelButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "#ffffff",
    color: "#111111",
    border: "1px solid #e1e1e1",
    padding: "10px 18px",
    borderRadius: "24px",
    fontSize: "0.9rem",
    fontWeight: "700",
    cursor: "pointer",
    transition: "all 0.15s ease",
  },
  buttonRow: {
    display: "flex",
    gap: "10px",
  },
  glassCard: {
    background: "#ffffff",
    border: "1px solid #e1e1e1",
    borderRadius: "24px",
    padding: "28px",
    boxShadow: "0 4px 12px rgba(0, 0, 0, 0.05)",
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
    background: "var(--primary, #800020)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
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
    fontWeight: "800",
    color: "#111111",
    margin: "0 0 4px 0",
  },
  email: {
    fontSize: "0.875rem",
    color: "#767676",
    margin: 0,
    fontWeight: "600",
  },
  streakCard: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    background: "#fef3c7",
    border: "1px solid #fde68a",
    padding: "12px 20px",
    borderRadius: "20px",
  },
  streakFlame: {
    fontSize: "28px",
  },
  streakCount: {
    fontSize: "1.25rem",
    fontWeight: "800",
    color: "#b45309",
    lineHeight: 1,
  },
  streakLabel: {
    fontSize: "0.75rem",
    fontWeight: "700",
    color: "#d97706",
    textTransform: "uppercase",
    letterSpacing: "0.05em",
    marginTop: "2px",
  },
  divider: {
    height: "1px",
    background: "#e1e1e1",
    margin: "24px 0",
  },
  gridContainer: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
    gap: "16px",
  },
  infoCard: {
    background: "#f7f7f7",
    border: "1px solid #e1e1e1",
    borderRadius: "20px",
    padding: "18px 20px",
    display: "flex",
    flexDirection: "column",
    gap: "6px",
  },
  infoLabel: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    fontSize: "0.78rem",
    fontWeight: "700",
    color: "#767676",
    textTransform: "uppercase",
    letterSpacing: "0.06em",
  },
  infoIcon: {
    color: "var(--primary, #800020)",
    fontSize: "16px",
  },
  infoValue: {
    fontSize: "1.05rem",
    fontWeight: "700",
    color: "#111111",
  },
  subtext: {
    fontSize: "0.75rem",
    color: "#767676",
    fontWeight: "600",
  },
  selectField: {
    background: "#ffffff",
    border: "1px solid #e1e1e1",
    borderRadius: "12px",
    padding: "8px 12px",
    color: "#111111",
    fontSize: "0.95rem",
    fontWeight: "600",
    outline: "none",
    width: "100%",
  },
  option: {
    background: "#ffffff",
    color: "#111111",
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
    background: "var(--primary, #800020)",
    color: "#ffffff",
    border: "none",
    padding: "10px 24px",
    borderRadius: "24px",
    fontSize: "0.95rem",
    fontWeight: "700",
    cursor: "pointer",
    transition: "all 0.15s ease",
  },
  errorBanner: {
    background: "#ffebe9",
    border: "1px solid #ffd0cc",
    color: "var(--primary, #800020)",
    padding: "12px 16px",
    borderRadius: "16px",
    marginBottom: "16px",
    fontSize: "0.9rem",
    fontWeight: "600",
  },
  successBanner: {
    background: "#e6f4ea",
    border: "1px solid #b7e1cd",
    color: "#00875a",
    padding: "12px 16px",
    borderRadius: "16px",
    marginBottom: "16px",
    fontSize: "0.9rem",
    fontWeight: "600",
  },
  loaderContainer: {
    width: "100%",
    height: "100vh",
    background: "var(--bg, #ffffff)",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
  },
  spinner: {
    width: "40px",
    height: "40px",
    border: "3px solid #e1e1e1",
    borderTop: "3px solid var(--primary, #800020)",
    borderRadius: "50%",
    animation: "spin 0.8s linear infinite",
  },
  loaderText: {
    marginTop: "12px",
    color: "#767676",
    fontSize: "0.9rem",
    fontWeight: "600",
  },
};