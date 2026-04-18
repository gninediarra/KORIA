// src/components/Header.jsx
import React, { useState, useEffect, useContext } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Menu, X, Sun, Moon, UserPlus } from 'lucide-react';
import { ThemeContext } from '../App';

const Header = () => {
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [scrollProgress, setScrollProgress] = useState(0);
  const { theme, toggleTheme } = useContext(ThemeContext);
  const location = useLocation();
  const navigate = useNavigate();
  const isDark = theme === 'dark';

  useEffect(() => {
    const handleScroll = () => {
      const totalScroll = document.documentElement.scrollHeight - window.innerHeight;
      const currentProgress = totalScroll > 0 ? (window.scrollY / totalScroll) * 100 : 0;
      setScrollProgress(currentProgress);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navItems = [
    { name: 'Overview', path: '/' },
    { name: 'Carte', path: '/carte' },
    { name: 'Dashboard', path: '/dashboard' },
    { name: 'Alert', path: '/alertes' },
  ];

  return (
    <header className={`fixed top-0 left-0 right-0 h-20 backdrop-blur-xl border-b z-[100] transition-all duration-700 ${
      isDark ? 'bg-[#080e1a]/80 text-white border-white/5' : 'bg-white/80 text-gray-900 border-gray-200 shadow-sm'
    }`}>
      {/* Notion-style Progress Bar */}
      <div className="absolute -bottom-[1px] left-0 h-[2px] bg-gradient-to-r from-transparent via-[#00d4ff] to-[#00d4ff] z-[110] transition-all duration-150 ease-out shadow-[0_0_8px_rgba(0,212,255,0.5)]" style={{ width: `${scrollProgress}%` }} />

      {/* Contenido principal del header */}
      <div className="relative z-10 max-w-7xl mx-auto px-8 h-full flex items-center justify-between">
        
        {/* Logo + Nombre */}
        <Link to="/" className="flex items-center gap-x-3 group">
          <div className={`w-10 h-10 rounded-2xl flex items-center justify-center text-2xl shadow-inner transition-transform group-hover:scale-110 ${
            isDark ? 'bg-white text-[#1e3a8a]' : 'bg-[#1e3a8a] text-white'
          }`}>
            👁️
          </div>
          <div className="flex items-baseline gap-x-1">
            <span className={`text-3xl font-bold tracking-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>Gabès</span>
            <span className="text-3xl font-bold tracking-tight text-[#00d4ff]">Eye</span>
          </div>
        </Link>

        {/* Navegación Desktop */}
        <nav className="hidden md:flex items-center gap-x-10 text-[13px] font-medium tracking-widest uppercase">
          {navItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`relative py-1 transition-all duration-300 hover:text-[#00d4ff] ${
                location.pathname === item.path
                  ? 'text-[#00d4ff]'
                  : isDark ? 'text-white/50' : 'text-gray-400'
              }`}
            >
              {item.name}
            </Link>
          ))}
        </nav>

        {/* Acciones derecha */}
        <div className="flex items-center gap-x-6">
          {/* Sign In */}
          <button 
            onClick={() => navigate('/signin')}
            className={`hidden lg:block text-[13px] font-medium transition-colors ${
              isDark ? 'text-white/70 hover:text-white' : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Sign in
          </button>

          {/* Create Account */}
          <button 
            onClick={() => navigate('/signup')}
            className={`p-2 rounded-full transition-all duration-300 hover:scale-110 active:scale-95 ${
              isDark ? 'bg-white/5 text-white hover:bg-white/10' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
            title="Create account"
          >
            <UserPlus size={19} strokeWidth={1.5} />
          </button>

          <div className={`h-5 w-px ${isDark ? 'bg-white/10' : 'bg-gray-200'} hidden sm:block`} />

          {/* Theme Toggle */}
          <button 
            onClick={toggleTheme}
            className={`p-2.5 rounded-2xl transition-all duration-500 hover:scale-110 active:scale-95 ${
              isDark ? 'bg-white/5 text-yellow-400 hover:bg-white/10' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
            aria-label="Toggle Theme"
          >
            {isDark ? <Sun size={20} /> : <Moon size={20} />}
          </button>

          {/* Botón de connexion / Profil */}
          <Link
            to="/profile"
            className={`flex items-center gap-x-3 px-6 py-2.5 rounded-3xl text-sm font-semibold transition-all border ${
              isDark 
                ? 'bg-white/5 hover:bg-white/10 border-white/10 text-white hover:border-[#00d4ff]' 
                : 'bg-white hover:bg-gray-50 border-gray-200 text-gray-900 shadow-sm hover:border-[#00d4ff]'
            }`}
          >
            <span className="hidden md:inline">Profil</span>
            <div className="w-8 h-8 bg-[#00d4ff] text-white rounded-2xl flex items-center justify-center text-xl shadow-inner">
              👤
            </div>
          </Link>

          {/* Botón menú móvil */}
          <button
            onClick={() => setIsMobileOpen(!isMobileOpen)}
            className={`md:hidden p-3 rounded-2xl transition-colors ${isDark ? 'hover:bg-white/10' : 'hover:bg-gray-100'}`}
          >
            {isMobileOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>

      {/* Menú móvil */}
      {isMobileOpen && (
        <div className={`md:hidden absolute top-20 left-0 right-0 border-t shadow-2xl py-6 z-50 transition-colors duration-700 ${
          isDark ? 'bg-[#080e1a] border-white/10 text-white' : 'bg-white border-gray-100 text-gray-900'
        }`}>
          <div className="max-w-7xl mx-auto px-8 flex flex-col gap-y-6 text-lg font-medium">
            {navItems.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                onClick={() => setIsMobileOpen(false)}
                className={`py-3 border-b last:border-none hover:text-[#00d4ff] transition-colors ${
                  isDark ? 'border-white/5' : 'border-gray-50'
                }`}
              >
                {item.name}
              </Link>
            ))}
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;