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
    background: "#ffffff",
    color: "#171717",
    fontFamily: "Inter, system-ui, -apple-system, sans-serif",
    padding: "36px 42px 60px",
    boxSizing: "border-box",
  },

  mainWrapper: {
    width: "100%",
    maxWidth: "1180px",
    margin: "0 auto",
  },

  topBar: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-end",
    marginBottom: "28px",
    flexWrap: "wrap",
    gap: "16px",
  },

  mainTitle: {
    fontSize: "2.35rem",
    fontWeight: "800",
    letterSpacing: "-0.04em",
    margin: "0 0 6px 0",
    color: "#171717",
  },

  subtitle: {
    fontSize: "0.95rem",
    color: "#737373",
    margin: 0,
    fontWeight: "600",
  },

  primaryButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "#8f0d2e",
    color: "#ffffff",
    border: "1px solid #8f0d2e",
    padding: "11px 20px",
    borderRadius: "999px",
    fontSize: "0.9rem",
    fontWeight: "700",
    cursor: "pointer",
    transition: "all 0.2s ease",
  },

  cancelButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "#ffffff",
    color: "#262626",
    border: "1px solid #d4d4d4",
    padding: "11px 20px",
    borderRadius: "999px",
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
    border: "1px solid #e5e5e5",
    borderRadius: "22px",
    padding: "30px",
    boxShadow: "0 8px 28px rgba(0,0,0,0.04)",
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
    borderRadius: "50%",
    background: "#171717",
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
    fontSize: "1.4rem",
    fontWeight: "800",
    color: "#171717",
    margin: "0 0 5px 0",
  },

  email: {
    fontSize: "0.9rem",
    color: "#737373",
    margin: 0,
    fontWeight: "600",
  },

  streakCard: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    background: "#fff8eb",
    border: "1px solid #efdfc1",
    padding: "14px 20px",
    borderRadius: "16px",
  },

  streakFlame: {
    fontSize: "28px",
  },

  streakCount: {
    fontSize: "1.3rem",
    fontWeight: "800",
    color: "#171717",
    lineHeight: 1,
  },

  streakLabel: {
    fontSize: "0.72rem",
    fontWeight: "700",
    color: "#8a6b2d",
    textTransform: "uppercase",
    letterSpacing: "0.08em",
    marginTop: "4px",
  },

  divider: {
    height: "1px",
    background: "#e5e5e5",
    margin: "26px 0",
  },

  gridContainer: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
    gap: "16px",
  },

  infoCard: {
    background: "#f7f7f7",
    border: "1px solid #e5e5e5",
    borderRadius: "18px",
    padding: "20px",
    display: "flex",
    flexDirection: "column",
    gap: "7px",
  },

  infoLabel: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    fontSize: "0.75rem",
    fontWeight: "800",
    color: "#737373",
    textTransform: "uppercase",
    letterSpacing: "0.08em",
  },

  infoIcon: {
    color: "#8f0d2e",
    fontSize: "16px",
  },

  infoValue: {
    fontSize: "1.05rem",
    fontWeight: "700",
    color: "#171717",
  },

  subtext: {
    fontSize: "0.78rem",
    color: "#8a8a8a",
  },

  selectField: {
    background: "#ffffff",
    border: "1px solid #d4d4d4",
    borderRadius: "10px",
    padding: "10px 12px",
    color: "#171717",
    fontSize: "0.95rem",
    fontWeight: "600",
    outline: "none",
    width: "100%",
  },

  option: {
    background: "#ffffff",
    color: "#171717",
  },

  saveContainer: {
    display: "flex",
    justifyContent: "flex-end",
    marginTop: "22px",
  },

  saveButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "#8f0d2e",
    color: "#ffffff",
    border: "1px solid #8f0d2e",
    padding: "11px 24px",
    borderRadius: "999px",
    fontSize: "0.95rem",
    fontWeight: "700",
    cursor: "pointer",
    transition: "all 0.2s ease",
  },

  errorBanner: {
    background: "#fff2f3",
    border: "1px solid #f1c8cf",
    color: "#8f0d2e",
    padding: "12px 16px",
    borderRadius: "16px",
    marginBottom: "16px",
    fontSize: "0.9rem",
    fontWeight: "600",
  },

  successBanner: {
    background: "#f2faf4",
    border: "1px solid #cce8d3",
    color: "#26733b",
    padding: "12px 16px",
    borderRadius: "16px",
    marginBottom: "16px",
    fontSize: "0.9rem",
    fontWeight: "600",
  },

  loaderContainer: {
    width: "100%",
    height: "100vh",
    minHeight: "400px",
    background: "#ffffff",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
  },

  spinner: {
    width: "40px",
    height: "40px",
    border: "3px solid #eeeeee",
    borderTop: "3px solid #8f0d2e",
    borderRadius: "50%",
    animation: "spin 0.8s linear infinite",
  },

  loaderText: {
    marginTop: "12px",
    color: "#737373",
    fontSize: "0.9rem",
    fontWeight: "600",
  },
};