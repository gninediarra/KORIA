import React, { useContext, useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, Lock, ArrowRight, Globe, Briefcase, Eye, EyeOff, Activity, Droplets, Wind } from 'lucide-react';
import { ThemeContext } from '../App';

const RECENT = [
  { icon: Activity, label: 'Alerte SO₂ détectée',    time: 'il y a 2 min',  color: '#f59e0b' },
  { icon: Droplets, label: 'Qualité eau — Niveau 3', time: 'il y a 8 min',  color: '#3b82f6' },
  { icon: Wind,     label: 'Indice air amélioré',    time: 'il y a 15 min', color: '#22c55e' },
];

const SignIn = () => {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';
  const [showPwd, setShowPwd] = useState(false);

  const cardStyle = isDark
    ? { background: 'rgba(10,18,35,0.55)', backdropFilter: 'blur(40px) saturate(180%)', WebkitBackdropFilter: 'blur(40px) saturate(180%)', border: '1px solid rgba(255,255,255,0.08)', boxShadow: '0 32px 80px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.06)' }
    : { background: 'rgba(224,242,255,0.60)', backdropFilter: 'blur(40px) saturate(200%)', WebkitBackdropFilter: 'blur(40px) saturate(200%)', border: '1px solid rgba(255,255,255,0.85)', boxShadow: '0 32px 80px rgba(0,100,200,0.12), inset 0 1px 0 rgba(255,255,255,0.95)' };

  const leftStyle = isDark
    ? { background: 'rgba(8,14,26,0.70)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRight: '1px solid rgba(255,255,255,0.06)' }
    : { background: 'linear-gradient(135deg, rgba(0,100,200,0.85) 0%, rgba(0,180,220,0.80) 100%)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRight: '1px solid rgba(255,255,255,0.30)' };

  const inputStyle = isDark
    ? { background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.10)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.06), 0 1px 3px rgba(0,0,0,0.3)' }
    : { background: 'rgba(255,255,255,0.55)', border: '1px solid rgba(180,220,255,0.70)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.95), 0 1px 4px rgba(0,100,200,0.08)' };

  const socialStyle = isDark
    ? { background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)' }
    : { background: 'rgba(255,255,255,0.55)', border: '1px solid rgba(180,220,255,0.65)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.95)' };

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      {/* Ambient blobs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="absolute top-1/3 left-1/3 w-96 h-96 rounded-full blur-[120px]"
          style={{ background: 'radial-gradient(circle, #00d4ff, transparent)', opacity: isDark ? 0.20 : 0.35 }} />
        <div className="absolute bottom-1/3 right-1/4 w-72 h-72 rounded-full blur-[100px]"
          style={{ background: 'radial-gradient(circle, #7c3aed, transparent)', opacity: isDark ? 0.15 : 0.25 }} />
        {!isDark && <div className="absolute top-1/2 left-1/4 w-64 h-64 rounded-full blur-[100px]"
          style={{ background: 'radial-gradient(circle, #0066ff, transparent)', opacity: 0.20 }} />}
      </div>

      <div className="w-full max-w-4xl grid lg:grid-cols-[1fr_1.1fr] overflow-hidden rounded-3xl" style={cardStyle}>

        {/* Left panel */}
        <div className="relative hidden lg:flex flex-col justify-between p-10 overflow-hidden" style={leftStyle}>
          <div className="absolute -top-16 -left-16 w-64 h-64 rounded-full opacity-25 blur-3xl"
            style={{ background: 'radial-gradient(circle, #00d4ff, transparent)' }} />
          <div className="absolute bottom-8 right-0 w-48 h-48 rounded-full opacity-15 blur-3xl"
            style={{ background: 'radial-gradient(circle, #7c3aed, transparent)' }} />

          <div>
            <div className="flex items-center gap-3 mb-10">
              <div className="w-9 h-9 rounded-xl flex items-center justify-center"
                style={{ background: 'linear-gradient(135deg, #00d4ff, #0066ff)' }}>
                <Globe size={18} className="text-white" />
              </div>
              <span className="text-white font-bold text-lg tracking-tight">GabèsEye</span>
            </div>
            <h2 className="text-3xl font-bold text-white leading-tight mb-4">
              Bon retour<br />
              <span style={{ background: 'linear-gradient(90deg, #00d4ff, #7c3aed)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                sur le réseau
              </span>
            </h2>
            <p className="text-white/40 text-sm leading-relaxed mb-8">
              Accédez aux données environnementales en temps réel de la région de Gabès.
            </p>

            <div className="space-y-3">
              <p className="text-[10px] font-bold uppercase tracking-widest text-white/20 mb-4">Activité récente</p>
              {RECENT.map(({ icon: Icon, label, time, color }) => (
                <div key={label} className="flex items-center gap-3 rounded-xl p-3"
                  style={{ background: 'rgba(255,255,255,0.12)', border: '1px solid rgba(255,255,255,0.22)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)' }}>
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                    style={{ background: `${color}18` }}>
                    <Icon size={14} style={{ color }} />
                  </div>
                  <div className="min-w-0">
                    <div className="text-xs text-white/70 font-medium truncate">{label}</div>
                    <div className="text-[10px] text-white/25">{time}</div>
                  </div>
                  <div className="w-1.5 h-1.5 rounded-full flex-shrink-0 animate-pulse" style={{ background: color }} />
                </div>
              ))}
            </div>
          </div>
          <p className="text-[10px] text-white/15 mt-6">Données mises à jour en continu · Surveillance 24/7</p>
        </div>

        {/* Right panel */}
        <div className="p-8 lg:p-10 flex flex-col justify-center">
          <div className="mb-8">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-6 lg:hidden"
              style={{ background: 'linear-gradient(135deg, #00d4ff, #0066ff)' }}>
              <Globe size={18} className="text-white" />
            </div>
            <h1 className={`text-2xl font-bold mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Connexion</h1>
            <p className={`text-sm ${isDark ? 'text-white/30' : 'text-blue-900/50'}`}>
              Entrez vos identifiants pour accéder à GabèsEye
            </p>
          </div>

          <div className="space-y-4">
            {/* Email */}
            <div>
              <label className={`block text-[11px] font-bold uppercase tracking-[0.15em] mb-2 ${isDark ? 'text-white/40' : 'text-blue-900/50'}`}>
                Adresse Email
              </label>
              <div className="relative group">
                <Mail size={15} className={`absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none transition-colors duration-200 ${isDark ? 'text-white/25 group-focus-within:text-[#00d4ff]' : 'text-gray-300 group-focus-within:text-[#00d4ff]'}`} />
                <input
                  type="email"
                  placeholder="contact@exemple.com"
                  style={inputStyle}
                  className={`w-full pl-11 pr-4 py-3.5 rounded-xl text-sm outline-none transition-all duration-200 focus:ring-2 focus:ring-[#00d4ff]/25 ${isDark ? 'text-white placeholder-white/20' : 'text-gray-900 placeholder-gray-400'}`}
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <div className="flex justify-between items-center mb-2">
                <label className={`text-[11px] font-bold uppercase tracking-[0.15em] ${isDark ? 'text-white/40' : 'text-blue-900/50'}`}>
                  Mot de passe
                </label>
                <button type="button" className="text-[11px] font-semibold text-[#00d4ff] hover:underline">
                  Mot de passe oublié ?
                </button>
              </div>
              <div className="relative group">
                <Lock size={15} className={`absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none transition-colors duration-200 ${isDark ? 'text-white/25 group-focus-within:text-[#00d4ff]' : 'text-gray-300 group-focus-within:text-[#00d4ff]'}`} />
                <input
                  type={showPwd ? 'text' : 'password'}
                  placeholder="••••••••"
                  style={inputStyle}
                  className={`w-full pl-11 pr-11 py-3.5 rounded-xl text-sm outline-none transition-all duration-200 focus:ring-2 focus:ring-[#00d4ff]/25 ${isDark ? 'text-white placeholder-white/20' : 'text-gray-900 placeholder-gray-400'}`}
                />
                <button type="button" onClick={() => setShowPwd(v => !v)}
                  className={`absolute right-4 top-1/2 -translate-y-1/2 transition-colors ${isDark ? 'text-white/25 hover:text-white/60' : 'text-gray-300 hover:text-gray-600'}`}>
                  {showPwd ? <EyeOff size={15} /> : <Eye size={15} />}
                </button>
              </div>
            </div>

            {/* Remember */}
            <label className={`flex items-center gap-2.5 cursor-pointer text-xs select-none ${isDark ? 'text-white/30' : 'text-blue-900/50'}`}>
              <input type="checkbox" className="accent-[#00d4ff] w-3.5 h-3.5" />
              Se souvenir de moi
            </label>

            {/* CTA */}
            <button
              className="w-full py-3.5 rounded-xl text-sm font-bold text-white flex items-center justify-center gap-2 group transition-all duration-200 hover:opacity-90 active:scale-[0.98]"
              style={{ background: 'linear-gradient(135deg, #00d4ff, #0066ff)' }}>
              Se connecter <ArrowRight size={16} className="group-hover:translate-x-0.5 transition-transform" />
            </button>
          </div>

          {/* Divider */}
          <div className="relative my-7 flex items-center gap-4">
            <div className={`flex-1 h-px ${isDark ? 'bg-white/5' : 'bg-gray-200/60'}`} />
            <span className={`text-[10px] font-bold uppercase tracking-widest ${isDark ? 'text-white/20' : 'text-gray-400'}`}>ou</span>
            <div className={`flex-1 h-px ${isDark ? 'bg-white/5' : 'bg-gray-200/60'}`} />
          </div>

          {/* Social */}
          <div className="grid grid-cols-2 gap-3">
            {[{ icon: Globe, label: 'Google' }, { icon: Briefcase, label: 'GitHub' }].map(({ icon: Icon, label }) => (
              <button key={label}
                className={`flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-medium transition-all ${isDark ? 'text-white/60 hover:text-white' : 'text-blue-900/70 hover:text-blue-900'}`}
                style={socialStyle}>
                <Icon size={16} /> {label}
              </button>
            ))}
          </div>

          <p className={`mt-7 text-center text-xs ${isDark ? 'text-white/25' : 'text-blue-900/40'}`}>
            Pas encore de compte ?{' '}
            <Link to="/signup" className="text-[#00d4ff] font-semibold hover:underline">S'inscrire</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default SignIn;
