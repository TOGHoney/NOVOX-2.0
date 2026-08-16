import { useState } from 'react';
import { FiMenu } from 'react-icons/fi';
import { Outlet } from 'react-router-dom';

import Header from '../components/Header';
import Sidebar from '../components/Sidebar';

export default function AppLayout() {
    const [mobileOpen, setMobileOpen] = useState(false);
    const [sidebarOpen, setSidebarOpen] = useState(true);

    return (
        <div className={`app-shell ${sidebarOpen ? '' : 'sidebar-collapsed'}`}>
            <button
                className={`sidebar-toggle-btn ${
                    sidebarOpen ? 'sidebar-open' : 'sidebar-closed'
                }`}
                onClick={() => setSidebarOpen((prev) => !prev)}
                aria-label="Toggle navigation"
            >
                <FiMenu size={20} />
            </button>

            <Sidebar
                mobileOpen={mobileOpen}
                setMobileOpen={setMobileOpen}
                sidebarOpen={sidebarOpen}
                setSidebarOpen={setSidebarOpen}
            />

            <div className="app-main">
                <Header setMobileOpen={setMobileOpen} />

                <main className="content-area">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}