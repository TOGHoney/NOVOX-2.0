import { Routes, Route, Navigate } from 'react-router-dom';
import { LanguageProvider } from './context/LanguageContext';
import { BookmarksProvider } from './context/BookmarksContext';
import AppLayout from './layouts/AppLayout';
import { ProtectedRoute } from './components/ProtectedRoutes';
import Login from './pages/login';
import Signup from './pages/Signup';
import Home from './pages/Home';
import Articles from './pages/Articles';
import Debates from './pages/Debates';
import DebateRoom from './pages/DebateRoom';
import Progress from './pages/Progress';
import Profile from './pages/Profile';
import NotFound from './pages/NotFound';
import AdminContestPanel from './components/AdminContestPanel';

import LearningProfile from './pages/LearningProfile';

export default function App() {
  return (
    <LanguageProvider>
      <BookmarksProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/learning-profile" element={<LearningProfile />} />
            <Route element={<AppLayout />}>
              <Route path="/" element={<Home />} />
              <Route path="/explore" element={<Navigate to="/" replace />} />
              <Route path="/articles" element={<Articles />} />
              
              <Route path="/debates" element={<Debates />} />
              <Route path="/debates/:id" element={<DebateRoom />} />
              <Route path="/progress" element={<Progress />} />
              <Route path="/profile" element={<Profile />} />
              <Route path="/admin" element={<AdminContestPanel />} />
              <Route path="/admin/contests" element={<AdminContestPanel />} />
              <Route path="/admin-contest" element={<AdminContestPanel />} />
              <Route path="/contests/admin" element={<AdminContestPanel />} />
            </Route>
          </Route>

          <Route path="*" element={<NotFound />} />
        </Routes>
      </BookmarksProvider>
    </LanguageProvider>
  );
}

