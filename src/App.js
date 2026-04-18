import React, { useEffect, useState, createContext, useContext } from 'react';
import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';
import Header from './components/Header';
import MapPage from './pages/MapPage';
import Dashboard from './pages/Dashboard';
import Alerts from './pages/Alerts';
import Overview from './pages/Overview';
import SignIn from './pages/SignIn';
import SignUp from './pages/SignUp';
import Footer from './components/Footer';
import ThreeBackground from './components/ThreeBackground';

export const ThemeContext = createContext();

const ScrollToTop = () => {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
};

const AppContent = () => {
  const location = useLocation();
  const { theme } = useContext(ThemeContext);
  const isOverview = location.pathname === '/';
  const isDark = theme === 'dark';

  return (
    <div className={`min-h-screen relative overflow-hidden transition-colors duration-700 ${isDark ? 'dark bg-[#080e1a]' : 'bg-gray-50'}`}>
      <ScrollToTop />
      {/* Fondo 3D Solo en Overview */}
      {isOverview && (
        <div className="fixed inset-0 z-0 pointer-events-none">
          <ThreeBackground theme={theme} />
        </div>
      )}
      
      {/* Contenido con z-index para estar sobre el fondo */}
      <div className="relative z-10 flex flex-col min-h-screen">
        <Header />
        <main className="flex-grow pt-20">
          <Routes>
            <Route path="/" element={<Overview />} />
            <Route path="/carte" element={<MapPage />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/alertes" element={<Alerts />} />
            <Route path="/signin" element={<SignIn />} />
            <Route path="/signup" element={<SignUp />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </div>
  );
};

function App() {
  const [theme, setTheme] = useState('dark');

  const toggleTheme = () => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark');
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      <BrowserRouter>
        <AppContent />
      </BrowserRouter>
    </ThemeContext.Provider>
  );
}

export default App;