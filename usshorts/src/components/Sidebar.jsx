import { NavLink, useNavigate } from 'react-router-dom';
import { FiAward, FiLogOut, FiBookOpen, FiCompass, FiHome, FiMessageCircle, FiUser } from 'react-icons/fi';
import '../styles/Sidebar.css';

const items = [
  { label: 'Articles', icon: FiBookOpen, path: '/articles' },
  { label: 'Debates', icon: FiMessageCircle, path: '/debates' },
  { label: 'Progress', icon: FiAward, path: '/progress' },
  { label: 'Profile', icon: FiUser, path: '/profile' }
];

export default function Sidebar({ isExploreOpen, setIsExploreOpen }) {
  const navigate = useNavigate();

  const logout = () => {
    localStorage.removeItem('user');
    navigate('/login');
  };

  return (
    <aside className="sidebar">
      {/* Top Logo */}
      <div className="logo-container">
        <div className="pinterest-logo">
          <span className="logo-icon">N</span>
        </div>
      </div>

      {/* Main Navigation */}
      <nav aria-label="Primary navigation" className="nav-list">
        <NavLink
          to="/"
          title="Home"
          className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
        >
          <FiHome size={22} />
        </NavLink>

        {/* Explore Drawer Toggle Button */}
        <button
          type="button"
          title="Explore"
          onClick={() => setIsExploreOpen((prev) => !prev)}
          className={`nav-item ${isExploreOpen ? 'active' : ''}`}
          style={{ background: 'none', border: 'none', cursor: 'pointer' }}
        >
          <FiCompass size={22} />
        </button>

        {items.map(({ label, icon: Icon, path }) => (
          <NavLink
            key={label}
            to={path}
            title={label}
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
          >
            <Icon size={22} />
          </NavLink>
        ))}
      </nav>

      {/* Bottom Actions */}
      <div className="sidebar-bottom">
        <button className="nav-item" title="Logout" onClick={logout}>
          <FiLogOut size={22} />
        </button>
      </div>
    </aside>
  );
}