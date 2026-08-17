import { useState } from 'react';
import { FiMenu } from 'react-icons/fi';
import { Outlet, useNavigate } from 'react-router-dom';

import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Explore from '../pages/Explore';

export default function AppLayout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isExploreOpen, setIsExploreOpen] = useState(false);
  
  // State to track the article selected from Explore
  const [selectedArticle, setSelectedArticle] = useState(null);

  const navigate = useNavigate();

  // Handle article selection from Explore
  const handleSelectArticle = (article) => {
    setSelectedArticle(article);
    setIsExploreOpen(false); // Close Explore drawer
    navigate('/articles');   // Redirect user to the Articles page instantly
  };

  // Calculate dynamic left offset:
  // Sidebar (72px) + Explore (360px) = 432px when Explore is open
  const sidebarWidth = sidebarOpen ? 72 : 0;
  const exploreWidth = 360;
  const mainMarginLeft = isExploreOpen ? `${sidebarWidth + exploreWidth}px` : `${sidebarWidth}px`;

  return (
    <div 
      className={`app-shell ${sidebarOpen ? '' : 'sidebar-collapsed'}`}
      style={{ display: 'flex', width: '100vw', minHeight: '100vh', overflowX: 'hidden' }}
    >
      <button
        className={`sidebar-toggle-btn ${
          sidebarOpen ? 'sidebar-open' : 'sidebar-closed'
        }`}
        onClick={() => setSidebarOpen((prev) => !prev)}
        aria-label="Toggle navigation"
      >
        <FiMenu size={20} />
      </button>

      {/* 1. Left Icon Sidebar (Fixed/Sticky) */}
      <Sidebar
        mobileOpen={mobileOpen}
        setMobileOpen={setMobileOpen}
        sidebarOpen={sidebarOpen}
        setSidebarOpen={setSidebarOpen}
        isExploreOpen={isExploreOpen}
        setIsExploreOpen={setIsExploreOpen}
      />

      {/* 2. Slide-out Explore Drawer (Fixed position) */}
      <Explore 
        isOpen={isExploreOpen} 
        onClose={() => setIsExploreOpen(false)} 
        onSelectArticle={handleSelectArticle}
      />

      {/* 3. Main Page Content */}
      <div 
        className="app-main" 
        style={{ 
          flex: 1, 
          minWidth: 0,
          /* Shift layout so fixed elements don't overlap content */
          marginLeft: mainMarginLeft, 
          paddingLeft: '0px', 
          transition: 'margin-left 0.3s cubic-bezier(0.16, 1, 0.3, 1)'
        }}
      >
        <Header setMobileOpen={setMobileOpen} />

        <main className="content-area" style={{ paddingLeft: '1.5rem', paddingRight: '1.5rem' }}>
          {/* Pass state to child routes via Outlet context */}
          <Outlet context={{ selectedArticle }} />
        </main>
      </div>
    </div>
  );
}