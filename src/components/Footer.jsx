// src/components/Footer.jsx
import React, { useContext } from 'react';
import { Link } from 'react-router-dom';
import { MessageCircle, Briefcase, Mail, MapPin, Phone, ExternalLink } from 'lucide-react';
import { ThemeContext } from '../App';

const Footer = () => {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  const footerLinks = {
    platform: [
      { name: 'Overview', path: '/' },
      { name: 'Carte Live', path: '/carte' },
      { name: 'Dashboard', path: '/dashboard' },
      { name: 'Alertes', path: '/alertes' },
    ],
    resources: [
      { name: 'Documentation', path: '/docs' },
      { name: 'API Reference', path: '#' },
      { name: 'Rapports Régionaux', path: '#' },
      { name: 'Méthodologie', path: '#' },
    ],
    legal: [
      { name: 'Confidentialité', path: '#' },
      { name: 'Conditions d\'utilisation', path: '#' },
      { name: 'Cookie Policy', path: '#' },
    ]
  };

  return (
    <footer className={`relative border-t transition-all duration-700 ${
      isDark ? 'bg-[#080e1a] border-white/5 text-white' : 'bg-white border-gray-100 text-gray-900 shadow-[0_-4px_20px_rgba(0,0,0,0.02)]'
    }`}>
      <div className="max-w-7xl mx-auto px-8 py-20">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-20">
          
          {/* Brand Section */}
          <div className="space-y-6">
            <Link to="/" className="flex items-center gap-x-3 group">
              <div className={`w-10 h-10 rounded-2xl flex items-center justify-center text-2xl shadow-inner transition-transform group-hover:scale-110 ${
                isDark ? 'bg-white text-[#1e3a8a]' : 'bg-[#1e3a8a] text-white'
              }`}>
                👁️
              </div>
              <div className="flex items-baseline gap-x-1">
                <span className={`text-2xl font-bold tracking-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>Gabès</span>
                <span className="text-2xl font-bold tracking-tight text-[#00d4ff]">Eye</span>
              </div>
            </Link>
            <p className={`text-sm leading-relaxed ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>
              Plateforme d'intelligence environnementale dédiée à la surveillance systémique et à la restauration écologique de la région de Gabès.
            </p>
            <div className="flex items-center gap-4">
              <button className={`p-2 rounded-xl transition-all ${isDark ? 'bg-white/5 hover:bg-white/10 text-white/50 hover:text-[#00d4ff]' : 'bg-gray-100 hover:bg-gray-200 text-gray-400 hover:text-[#00d4ff]'}`}>
                <MessageCircle size={18} />
              </button>
              <button className={`p-2 rounded-xl transition-all ${isDark ? 'bg-white/5 hover:bg-white/10 text-white/50 hover:text-[#00d4ff]' : 'bg-gray-100 hover:bg-gray-200 text-gray-400 hover:text-[#00d4ff]'}`}>
                <Briefcase size={18} />
              </button>
              <button className={`p-2 rounded-xl transition-all ${isDark ? 'bg-white/5 hover:bg-white/10 text-white/50 hover:text-[#00d4ff]' : 'bg-gray-100 hover:bg-gray-200 text-gray-400 hover:text-[#00d4ff]'}`}>
                <ExternalLink size={18} />
              </button>
            </div>
          </div>

          {/* Links Sections */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-[#00d4ff] mb-8">Plateforme</h4>
            <ul className="space-y-4">
              {footerLinks.platform.map(link => (
                <li key={link.name}>
                  <Link to={link.path} className={`text-sm transition-colors hover:text-[#00d4ff] ${isDark ? 'text-white/40' : 'text-gray-500'}`}>
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-[#00d4ff] mb-8">Ressources</h4>
            <ul className="space-y-4">
              {footerLinks.resources.map(link => (
                <li key={link.name}>
                  <Link to={link.path} className={`text-sm transition-colors hover:text-[#00d4ff] ${isDark ? 'text-white/40' : 'text-gray-500'}`}>
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Contact Section */}
          <div className="space-y-8">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-[#00d4ff]">Contact</h4>
            <ul className="space-y-4">
              <li className="flex items-start gap-4">
                <MapPin size={18} className="text-[#00d4ff] shrink-0" />
                <span className={`text-sm ${isDark ? 'text-white/40' : 'text-gray-500'}`}>Gabès, Tunisie — Technopole de Gabès</span>
              </li>
              <li className="flex items-center gap-4">
                <Mail size={18} className="text-[#00d4ff] shrink-0" />
                <span className={`text-sm ${isDark ? 'text-white/40' : 'text-gray-500'}`}>contact@gabeseye.org</span>
              </li>
              <li className="flex items-center gap-4">
                <Phone size={18} className="text-[#00d4ff] shrink-0" />
                <span className={`text-sm ${isDark ? 'text-white/40' : 'text-gray-500'}`}>+216 75 000 000</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className={`pt-10 border-t flex flex-col md:flex-row justify-between items-center gap-6 ${isDark ? 'border-white/5' : 'border-gray-100'}`}>
          <p className={`text-xs font-medium tracking-wide ${isDark ? 'text-white/20' : 'text-gray-400'}`}>
            © 2026 GABÈSEYE. TOUS DROITS RÉSERVÉS. PROJET HACKATHON.
          </p>
          <div className="flex items-center gap-8">
            {footerLinks.legal.map(link => (
              <button key={link.name} className={`text-xs font-bold uppercase tracking-widest transition-colors hover:text-[#00d4ff] ${isDark ? 'text-white/20' : 'text-gray-400'}`}>
                {link.name}
              </button>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;