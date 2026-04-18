import React, { useContext, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Mail, Lock, User, ArrowRight, Globe, MapPin, Briefcase,
  LandPlot, ChevronRight, Sprout, Fish, Users, Shield, Check, Eye, EyeOff, X
} from 'lucide-react';
import { ThemeContext } from '../App';

const ROLES = [
  { value: 'agriculteur', label: 'Agriculteur', icon: Sprout, desc: 'Surveillance des terres agricoles', color: '#22c55e' },
  { value: 'pecheur',     label: 'Pêcheur',     icon: Fish,   desc: 'Suivi de la qualité marine',        color: '#3b82f6' },
  { value: 'citoyen',     label: 'Citoyen',     icon: Users,  desc: 'Signalement environnemental',       color: '#a855f7' },
  { value: 'autorite',    label: 'Autorité',    icon: Shield, desc: 'Gestion et supervision',            color: '#f59e0b' },
];

const STEPS = ['Identité', 'Rôle', 'Sécurité'];

const RULES = [
  { id: 'len',   label: '8 caractères minimum', test: v => v.length >= 8 },
  { id: 'upper', label: 'Une lettre majuscule',  test: v => /[A-Z]/.test(v) },
  { id: 'num',   label: 'Un chiffre ou symbole', test: v => /[\d\W]/.test(v) },
];

const glassInput = (isDark) => ({
  style: isDark
    ? { background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.10)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.06), 0 1px 3px rgba(0,0,0,0.3)' }
    : { background: 'rgba(255,255,255,0.55)', border: '1px solid rgba(180,220,255,0.70)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.95), 0 1px 4px rgba(0,100,200,0.08)' },
});

const GlassInput = ({ icon: Icon, label, type = 'text', placeholder, isDark, right, value, onChange }) => {
  const { style } = glassInput(isDark);
  return (
    <div>
      <label className={`block text-[11px] font-bold uppercase tracking-[0.15em] mb-2 ${isDark ? 'text-white/40' : 'text-blue-900/50'}`}>
        {label}
      </label>
      <div className="relative group">
        <Icon size={15} className={`absolute left-4 top-1/2 -translate-y-1/2 transition-colors duration-200 pointer-events-none ${isDark ? 'text-white/25 group-focus-within:text-[#00d4ff]' : 'text-gray-300 group-focus-within:text-[#00d4ff]'}`} />
        <input
          type={type}
          placeholder={placeholder}
          value={value}
          onChange={onChange}
          style={style}
          className={`w-full pl-11 ${right ? 'pr-11' : 'pr-4'} py-3.5 rounded-xl text-sm outline-none transition-all duration-200 focus:ring-2 focus:ring-[#00d4ff]/25 ${isDark ? 'text-white placeholder-white/20 focus:border-[#00d4ff]/50' : 'text-gray-900 placeholder-gray-400 focus:border-[#00d4ff]/60'}`}
        />
        {right}
      </div>
    </div>
  );
};


const SignUp = () => {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';
  const [step, setStep]       = useState(0);
  const [role, setRole]       = useState('');
  const [pwd, setPwd]         = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  const [showCfm, setShowCfm] = useState(false);

  const progress   = ((step + 1) / STEPS.length) * 100;
  const matchOk    = pwd.length > 0 && pwd === confirm;
  const allRulesOk = RULES.every(r => r.test(pwd));

  const cardStyle = isDark
    ? { background: 'rgba(10,18,35,0.55)', backdropFilter: 'blur(40px) saturate(180%)', WebkitBackdropFilter: 'blur(40px) saturate(180%)', border: '1px solid rgba(255,255,255,0.08)', boxShadow: '0 32px 80px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.06)' }
    : { background: 'rgba(224,242,255,0.60)', backdropFilter: 'blur(40px) saturate(200%)', WebkitBackdropFilter: 'blur(40px) saturate(200%)', border: '1px solid rgba(255,255,255,0.85)', boxShadow: '0 32px 80px rgba(0,100,200,0.12), inset 0 1px 0 rgba(255,255,255,0.95)' };

  const leftStyle = isDark
    ? { background: 'rgba(8,14,26,0.70)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRight: '1px solid rgba(255,255,255,0.06)' }
    : { background: 'linear-gradient(135deg, rgba(0,100,200,0.85) 0%, rgba(0,180,220,0.80) 100%)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRight: '1px solid rgba(255,255,255,0.30)' };

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      {/* Ambient blobs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full blur-[120px]"
          style={{ background: 'radial-gradient(circle, #00d4ff, transparent)', opacity: isDark ? 0.20 : 0.35 }} />
        <div className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full blur-[100px]"
          style={{ background: 'radial-gradient(circle, #7c3aed, transparent)', opacity: isDark ? 0.15 : 0.25 }} />
        {!isDark && <div className="absolute top-1/2 right-1/3 w-64 h-64 rounded-full blur-[100px]"
          style={{ background: 'radial-gradient(circle, #0066ff, transparent)', opacity: 0.20 }} />}
      </div>

      <div className="w-full max-w-5xl grid lg:grid-cols-[1fr_1.1fr] overflow-hidden rounded-3xl" style={cardStyle}>

        {/* Left panel */}
        <div className="relative hidden lg:flex flex-col justify-between p-10 overflow-hidden" style={leftStyle}>
          <div className="absolute -top-20 -left-20 w-72 h-72 rounded-full opacity-25 blur-3xl"
            style={{ background: 'radial-gradient(circle, #00d4ff, transparent)' }} />
          <div className="absolute bottom-10 right-0 w-56 h-56 rounded-full opacity-15 blur-3xl"
            style={{ background: 'radial-gradient(circle, #7c3aed, transparent)' }} />
          <div>
            <div className="flex items-center gap-3 mb-10">
              <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: 'linear-gradient(135deg, #00d4ff, #0066ff)' }}>
                <Globe size={18} className="text-white" />
              </div>
              <span className="text-white font-bold text-lg tracking-tight">GabèsEye</span>
            </div>
            <h2 className="text-3xl font-bold text-white leading-tight mb-4">
              Rejoignez le réseau<br />
              <span style={{ background: 'linear-gradient(90deg, #00d4ff, #7c3aed)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                de surveillance
              </span>
            </h2>
            <p className="text-white/40 text-sm leading-relaxed">
              Plateforme collaborative de monitoring environnemental pour la région de Gabès.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-4">
            {[['2 400+','Membres actifs'],['98%','Précision données'],['24/7','Surveillance'],['12','Zones couvertes']].map(([v, l]) => (
              <div key={l} className="rounded-2xl p-4"
                style={{ background: 'rgba(255,255,255,0.10)', border: '1px solid rgba(255,255,255,0.20)', backdropFilter: 'blur(8px)' }}>
                <div className="text-xl font-bold text-white">{v}</div>
                <div className="text-xs text-white/50 mt-0.5">{l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Right panel */}
        <div className="p-8 lg:p-10">
          {/* Stepper */}
          <div className="mb-8">
            <div className="flex items-center justify-between mb-3">
              {STEPS.map((s, i) => (
                <React.Fragment key={s}>
                  <button onClick={() => i < step && setStep(i)} className="flex items-center gap-2">
                    <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 ${
                      i < step ? 'bg-[#00d4ff] text-white'
                      : i === step
                        ? isDark ? 'bg-white/10 text-white border border-[#00d4ff]/60' : 'bg-white/70 text-[#00d4ff] border border-[#00d4ff]'
                        : isDark ? 'bg-white/5 text-white/20' : 'bg-white/40 text-gray-400'
                    }`}>
                      {i < step ? <Check size={12} /> : i + 1}
                    </div>
                    <span className={`text-xs font-medium hidden sm:block ${i === step ? (isDark ? 'text-white' : 'text-gray-900') : (isDark ? 'text-white/25' : 'text-gray-400')}`}>{s}</span>
                  </button>
                  {i < STEPS.length - 1 && (
                    <div className={`flex-1 h-px mx-3 transition-all duration-500 ${i < step ? 'bg-[#00d4ff]' : isDark ? 'bg-white/5' : 'bg-gray-200/60'}`} />
                  )}
                </React.Fragment>
              ))}
            </div>
            <div className={`h-0.5 rounded-full overflow-hidden ${isDark ? 'bg-white/5' : 'bg-gray-200/50'}`}>
              <div className="h-full rounded-full transition-all duration-500"
                style={{ width: `${progress}%`, background: 'linear-gradient(90deg, #00d4ff, #7c3aed)' }} />
            </div>
          </div>

          {/* Title */}
          <div className="mb-7">
            <h1 className={`text-2xl font-bold mb-1 ${isDark ? 'text-white' : 'text-blue-950'}`}>
              {['Vos informations','Votre profil','Sécurisez votre compte'][step]}
            </h1>
            <p className={`text-sm ${isDark ? 'text-white/30' : 'text-blue-900/50'}`}>
              {['Dites-nous qui vous êtes','Choisissez votre rôle dans le réseau','Créez un mot de passe sécurisé'][step]}
            </p>
          </div>

          {/* Step 0 */}
          {step === 0 && (
            <div className="space-y-4">
              <GlassInput icon={User}   label="Nom Complet"           placeholder="Mohamed Ben Ali"        isDark={isDark} />
              <GlassInput icon={Mail}   label="Adresse Email"         placeholder="contact@exemple.com"    isDark={isDark} type="email" />
              <GlassInput icon={MapPin} label="Adresse Résidentielle" placeholder="Rue de l'Oasis, Gabès" isDark={isDark} />
            </div>
          )}

          {/* Step 1 */}
          {step === 1 && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                {ROLES.map(({ value, label, icon: Icon, desc, color }) => {
                  const sel = role === value;
                  return (
                    <button key={value} onClick={() => setRole(value)}
                      className="relative text-left p-4 rounded-2xl transition-all duration-200"
                      style={sel
                        ? { background: isDark ? 'rgba(0,212,255,0.07)' : 'rgba(0,212,255,0.10)', border: `1px solid ${color}50`, backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)' }
                        : { background: isDark ? 'rgba(255,255,255,0.03)' : 'rgba(255,255,255,0.55)', border: isDark ? '1px solid rgba(255,255,255,0.10)' : '1px solid rgba(180,220,255,0.60)', backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)' }
                      }>
                      {sel && (
                        <div className="absolute top-3 right-3 w-5 h-5 rounded-full bg-[#00d4ff] flex items-center justify-center">
                          <Check size={10} className="text-white" />
                        </div>
                      )}
                      <div className="w-9 h-9 rounded-xl flex items-center justify-center mb-3"
                        style={{ background: sel ? `${color}20` : isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)' }}>
                        <Icon size={18} style={{ color: sel ? color : isDark ? 'rgba(255,255,255,0.3)' : '#9ca3af' }} />
                      </div>
                      <div className={`text-sm font-semibold mb-0.5 ${isDark ? 'text-white' : 'text-blue-950'}`}>{label}</div>
                      <div className={`text-[11px] leading-tight ${isDark ? 'text-white/25' : 'text-blue-900/40'}`}>{desc}</div>
                    </button>
                  );
                })}
              </div>
              {role === 'agriculteur' && (
                <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
                  <GlassInput icon={LandPlot} label="ID de la Parcelle" placeholder="PARC-2026-X" isDark={isDark} />
                </div>
              )}
            </div>
          )}

          {/* Step 2 */}
          {step === 2 && (
            <div className="space-y-4">
              <GlassInput
                icon={Lock} label="Mot de passe" type={showPwd ? 'text' : 'password'}
                placeholder="••••••••" isDark={isDark}
                value={pwd} onChange={e => setPwd(e.target.value)}
                right={
                  <button type="button" onClick={() => setShowPwd(v => !v)}
                    className={`absolute right-4 top-1/2 -translate-y-1/2 transition-colors ${isDark ? 'text-white/25 hover:text-white/60' : 'text-gray-300 hover:text-gray-600'}`}>
                    {showPwd ? <EyeOff size={15} /> : <Eye size={15} />}
                  </button>
                }
              />

              {/* Real-time rules */}
              <div className="rounded-xl p-4 space-y-2.5"
                style={isDark
                  ? { background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)' }
                  : { background: 'rgba(255,255,255,0.60)', border: '1px solid rgba(180,220,255,0.70)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.95)' }
                }>
                {RULES.map(({ id, label, test }) => {
                  const ok = test(pwd);
                  return (
                    <div key={id} className="flex items-center gap-2.5 transition-all duration-200">
                      <div className={`w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 transition-all duration-300 ${ok ? 'bg-emerald-500/20' : isDark ? 'bg-white/5' : 'bg-gray-100'}`}>
                        {ok ? <Check size={11} className="text-emerald-400" /> : <X size={11} className={isDark ? 'text-white/20' : 'text-gray-300'} />}
                      </div>
                      <span className={`text-xs transition-colors duration-200 ${ok ? 'text-emerald-500 font-medium' : isDark ? 'text-white/30' : 'text-blue-900/40'}`}>
                        {label}
                      </span>
                    </div>
                  );
                })}
              </div>

              <GlassInput
                icon={Lock} label="Confirmation" type={showCfm ? 'text' : 'password'}
                placeholder="••••••••" isDark={isDark}
                value={confirm} onChange={e => setConfirm(e.target.value)}
                right={
                  <button type="button" onClick={() => setShowCfm(v => !v)}
                    className={`absolute right-4 top-1/2 -translate-y-1/2 transition-colors ${isDark ? 'text-white/25 hover:text-white/60' : 'text-gray-300 hover:text-gray-600'}`}>
                    {showCfm ? <EyeOff size={15} /> : <Eye size={15} />}
                  </button>
                }
              />

              {confirm.length > 0 && (
                <div className={`flex items-center gap-2 text-xs transition-all duration-200 ${matchOk ? 'text-emerald-400' : 'text-rose-400'}`}>
                  {matchOk ? <><Check size={13} /> Les mots de passe correspondent</> : <><X size={13} /> Les mots de passe ne correspondent pas</>}
                </div>
              )}

              <label className={`flex items-start gap-3 cursor-pointer text-xs ${isDark ? 'text-white/30' : 'text-blue-900/50'}`}>
                <input type="checkbox" className="mt-0.5 accent-[#00d4ff]" />
                <span>J'accepte les <span className="text-[#00d4ff] hover:underline cursor-pointer">conditions d'utilisation</span> et la <span className="text-[#00d4ff] hover:underline cursor-pointer">politique de confidentialité</span></span>
              </label>
            </div>
          )}

          {/* Nav */}
          <div className="mt-8 flex gap-3">
            {step > 0 && (
              <button onClick={() => setStep(s => s - 1)}
                className={`px-5 py-3.5 rounded-xl text-sm font-semibold transition-all ${isDark ? 'text-white/50 hover:text-white' : 'text-blue-900/60 hover:text-blue-950'}`}
                style={isDark
                  ? { background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', backdropFilter: 'blur(12px)' }
                  : { background: 'rgba(255,255,255,0.55)', border: '1px solid rgba(180,220,255,0.65)', backdropFilter: 'blur(12px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.95)' }
                }>
                Retour
              </button>
            )}
            <button
              onClick={() => step < STEPS.length - 1 ? setStep(s => s + 1) : undefined}
              disabled={step === 2 && (!allRulesOk || !matchOk)}
              className="flex-1 py-3.5 rounded-xl text-sm font-bold text-white flex items-center justify-center gap-2 group transition-all duration-200 hover:opacity-90 active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed"
              style={{ background: 'linear-gradient(135deg, #00d4ff, #0066ff)' }}>
              {step < STEPS.length - 1
                ? <>Continuer <ChevronRight size={16} className="group-hover:translate-x-0.5 transition-transform" /></>
                : <>Créer mon compte <ArrowRight size={16} className="group-hover:translate-x-0.5 transition-transform" /></>
              }
            </button>
          </div>

          {step === 0 && (
            <>
              <div className="relative my-7 flex items-center gap-4">
                <div className={`flex-1 h-px ${isDark ? 'bg-white/5' : 'bg-gray-200/60'}`} />
                <span className={`text-[10px] font-bold uppercase tracking-widest ${isDark ? 'text-white/20' : 'text-gray-400'}`}>ou</span>
                <div className={`flex-1 h-px ${isDark ? 'bg-white/5' : 'bg-gray-200/60'}`} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                {[{ icon: Globe, label: 'Google' }, { icon: Briefcase, label: 'GitHub' }].map(({ icon: Icon, label }) => (
                  <button key={label}
                    className={`flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-medium transition-all ${isDark ? 'text-white/60 hover:text-white' : 'text-blue-900/70 hover:text-blue-950'}`}
                    style={isDark
                      ? { background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', backdropFilter: 'blur(12px)' }
                      : { background: 'rgba(255,255,255,0.55)', border: '1px solid rgba(180,220,255,0.65)', backdropFilter: 'blur(12px)', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.95)' }
                    }>
                    <Icon size={16} /> {label}
                  </button>
                ))}
              </div>
            </>
          )}

          <p className={`mt-7 text-center text-xs ${isDark ? 'text-white/25' : 'text-blue-900/40'}`}>
            Déjà membre ?{' '}
            <Link to="/signin" className="text-[#00d4ff] font-semibold hover:underline">Se connecter</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default SignUp;
