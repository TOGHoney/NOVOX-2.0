import { NavLink, useNavigate } from 'react-router-dom';
import { FiAward, FiLogOut, FiBookOpen, FiCompass, FiHome, FiMessageCircle, FiUser, FiSettings } from 'react-icons/fi';
import '../styles/Sidebar.css';
const items = [
  { label: 'Home', icon: FiHome, path: '/' },
  { label: 'Explore', icon: FiCompass, path: '/explore' },
  { label: 'Articles', icon: FiBookOpen, path: '/articles' },
  { label: 'Debates', icon: FiMessageCircle, path: '/debates' },
  { label: 'Progress', icon: FiAward, path: '/progress' },
  { label: 'Profile', icon: FiUser, path: '/profile' }
];

export default function Sidebar() {
  const navigate = useNavigate();

  const logout = () => {
    localStorage.removeItem('user');
    navigate('/login');
  };

  return (
    <aside className="sidebar">
      {/* Top Logo Icon */}
      <div className="logo-container">
        <div className="pinterest-logo">
          {/* Replace with your logo SVG/Image */}
          <span className="logo-icon">N</span>
        </div>
      </div>

      {/* Main Navigation Icons */}
      <nav aria-label="Primary navigation" className="nav-list">
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

      {/* Bottom Action Icons */}
      <div className="sidebar-bottom">
        <button className="nav-item" title="Logout" onClick={logout}>
          <FiLogOut size={22} />
        </button>
      </div>
    </aside>
  );
}