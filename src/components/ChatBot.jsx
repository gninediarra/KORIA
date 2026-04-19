import React, { useCallback, useContext, useEffect, useRef, useState } from 'react';
import { MessageCircle, X, Send, Mic, MicOff, Volume2, VolumeX, ChevronDown, Eye, MessageSquare, User, Leaf, Anchor, Building2 } from 'lucide-react';
import { ThemeContext } from '../App';
import { api } from '../services/api';

// ── i18n ─────────────────────────────────────────────────────────────────────
const LANGS = [
  { code: 'fr', label: 'FR', dir: 'ltr', speechCode: 'fr-FR' },
  { code: 'en', label: 'EN', dir: 'ltr', speechCode: 'en-US' },
  { code: 'ar', label: 'AR', dir: 'rtl', speechCode: 'ar-SA' },
];

const I18N = {
  fr: {
    title: 'GabèsEye AI',
    subtitle: 'Assistant environnemental',
    placeholder: 'Posez votre question…',
    listening: 'Écoute en cours…',
    greeting: 'Bonjour ! Je suis GabèsEye AI. Comment puis-je vous aider ?',
    roles: { chat: 'Général', citoyen: 'Citoyen', agriculteur: 'Agriculteur', pecheur: 'Pêcheur', autorite: 'Autorité' },
  },
  en: {
    title: 'GabèsEye AI',
    subtitle: 'Environmental assistant',
    placeholder: 'Ask your question…',
    listening: 'Listening…',
    greeting: 'Hello! I am GabèsEye AI. How can I help you?',
    roles: { chat: 'General', citoyen: 'Citizen', agriculteur: 'Farmer', pecheur: 'Fisher', autorite: 'Authority' },
  },
  ar: {
    title: 'GabèsEye AI',
    subtitle: 'المساعد البيئي',
    placeholder: 'اطرح سؤالك…',
    listening: 'جارٍ الاستماع…',
    greeting: 'مرحباً! أنا GabèsEye AI. كيف يمكنني مساعدتك؟',
    roles: { chat: 'عام', citoyen: 'مواطن', agriculteur: 'مزارع', pecheur: 'صياد', autorite: 'سلطة' },
  },
};

const ROLE_ICONS = {
  chat:        MessageSquare,
  citoyen:     User,
  agriculteur: Leaf,
  pecheur:     Anchor,
  autorite:    Building2,
};

const ROLES = ['chat', 'citoyen', 'agriculteur', 'pecheur', 'autorite'];
const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

// ── Sub-components ────────────────────────────────────────────────────────────
function Bubble({ msg, isDark, isRtl }) {
  const isUser = msg.role === 'user';
  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'}`} dir={isRtl ? 'rtl' : 'ltr'}>
      <div className={`max-w-[82%] px-4 py-2.5 text-sm leading-relaxed whitespace-pre-wrap break-words ${
        isUser
          ? 'bg-[#00d4ff] text-[#080e1a] font-medium rounded-2xl rounded-br-sm shadow-[0_2px_16px_rgba(0,212,255,0.35)]'
          : isDark
          ? 'bg-white/10 text-white/85 rounded-2xl rounded-bl-sm border border-white/8 backdrop-blur-sm'
          : 'bg-white/90 text-gray-800 rounded-2xl rounded-bl-sm border border-gray-200/60 shadow-sm'
      }`}>
        {msg.content}
      </div>
    </div>
  );
}

function TypingDots({ isDark }) {
  return (
    <div className="flex justify-start">
      <div className={`px-4 py-3 rounded-2xl rounded-bl-sm border ${
        isDark ? 'bg-white/10 border-white/8' : 'bg-white/90 border-gray-200/60 shadow-sm'
      }`}>
        <span className="inline-flex gap-1 items-center h-4">
          {[0, 150, 300].map((d) => (
            <span key={d} className={`w-1.5 h-1.5 rounded-full animate-bounce ${isDark ? 'bg-white/40' : 'bg-gray-400'}`}
              style={{ animationDelay: `${d}ms` }} />
          ))}
        </span>
      </div>
    </div>
  );
}

// ── Main component ────────────────────────────────────────────────────────────
export default function ChatBot() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  const [open, setOpen]       = useState(false);
  const [lang, setLang]       = useState(() => localStorage.getItem('gabes_lang') || 'fr');
  const [role, setRole]       = useState('chat');
  const [messages, setMessages] = useState([]);
  const [input, setInput]     = useState('');
  const [loading, setLoading] = useState(false);
  const [ttsOn, setTtsOn]     = useState(true);
  const [listening, setListening] = useState(false);

  const t           = I18N[lang] || I18N.fr;
  const langMeta    = LANGS.find((l) => l.code === lang) || LANGS[0];
  const isRtl       = langMeta.dir === 'rtl';
  const sttSupported = !!SpeechRecognition;

  const bottomRef = useRef(null);
  const audioRef  = useRef(null);
  const recognRef = useRef(null);
  const historyRef = useRef([]);

  // Init greeting when lang changes
  useEffect(() => {
    setMessages([{ role: 'assistant', content: t.greeting }]);
  }, [lang]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    historyRef.current = messages.slice(1).map((m) => ({ role: m.role, content: m.content }));
  }, [messages]);

  useEffect(() => {
    if (open) bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, open]);

  // Persist lang
  useEffect(() => { localStorage.setItem('gabes_lang', lang); }, [lang]);

  // ── TTS ────────────────────────────────────────────────────────────────
  const speak = useCallback((text) => {
    if (!ttsOn) return;
    audioRef.current?.pause();
    const audio = new Audio(api.ttsUrl(text.slice(0, 500), lang));
    audioRef.current = audio;
    audio.play().catch(() => {
      if ('speechSynthesis' in window) {
        const utt = new SpeechSynthesisUtterance(text.slice(0, 300));
        utt.lang = langMeta.speechCode;
        window.speechSynthesis.speak(utt);
      }
    });
  }, [ttsOn, lang, langMeta.speechCode]);

  // ── STT ────────────────────────────────────────────────────────────────
  function toggleListening() {
    if (!sttSupported) return;
    if (listening) { recognRef.current?.stop(); setListening(false); return; }
    const recog = new SpeechRecognition();
    recog.lang = langMeta.speechCode;
    recog.interimResults = false;
    recog.onresult = (e) => setInput((p) => p + e.results[0][0].transcript);
    recog.onend = recog.onerror = () => setListening(false);
    recognRef.current = recog;
    recog.start();
    setListening(true);
  }

  // ── Send ───────────────────────────────────────────────────────────────
  async function send() {
    const text = input.trim();
    if (!text || loading) return;
    setInput('');
    setMessages((p) => [...p, { role: 'user', content: text }]);
    setLoading(true);
    try {
      const res = await api.chat({ message: text, history: historyRef.current.slice(-6), role, langue: lang, zone_id: 'gct' });
      const reply = res.response || '…';
      setMessages((p) => [...p, { role: 'assistant', content: reply }]);
      speak(reply);
    } finally {
      setLoading(false);
    }
  }

  function handleKey(e) { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } }

  function stopAudio() { audioRef.current?.pause(); window.speechSynthesis?.cancel(); }

  // ── Styles ─────────────────────────────────────────────────────────────
  const panel = isDark
    ? 'bg-[#0a0f1e]/80 backdrop-blur-2xl border border-white/10 shadow-[0_16px_48px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.05)]'
    : 'bg-white/70 backdrop-blur-2xl border border-white/80 shadow-[0_16px_48px_rgba(0,0,0,0.15),inset_0_1px_0_rgba(255,255,255,0.9)]';

  const divider = isDark ? 'border-white/8' : 'border-gray-200/60';

  const inputWrap = isDark
    ? 'bg-white/6 border border-white/10 backdrop-blur-sm'
    : 'bg-white/80 border border-gray-200/80 shadow-inner';

  return (
    <>
      {/* FAB */}
      <button
        onClick={() => setOpen((v) => !v)}
        className={`fixed bottom-6 right-6 z-[200] w-14 h-14 rounded-full flex items-center justify-center transition-all duration-300 hover:scale-110 active:scale-95 ${
          open
            ? 'bg-white/10 backdrop-blur-xl border border-[#00d4ff]/40 shadow-[0_4px_20px_rgba(0,212,255,0.2)]'
            : 'bg-[#00d4ff] shadow-[0_4px_24px_rgba(0,212,255,0.5)]'
        }`}
        aria-label="Toggle chat"
      >
        {open ? <ChevronDown size={22} className="text-[#00d4ff]" /> : <MessageCircle size={22} className="text-[#080e1a]" />}
      </button>

      {/* Panel */}
      {open && (
        <div
          dir={isRtl ? 'rtl' : 'ltr'}
          className={`fixed bottom-24 right-6 z-[200] w-80 sm:w-96 rounded-[24px] flex flex-col overflow-hidden ${panel}`}
          style={{ height: '70vh', maxHeight: 580, minHeight: 380 }}
        >
          {/* ── Header ── */}
          <div className={`flex-none flex items-center justify-between px-4 py-3 border-b ${divider}`}>
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-[#00d4ff] flex items-center justify-center shadow-[0_0_12px_rgba(0,212,255,0.4)]">
                <Eye size={16} strokeWidth={2} className="text-[#080e1a]" />
              </div>
              <div>
                <div className={`font-bold text-sm leading-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>{t.title}</div>
                <div className={`text-[11px] ${isDark ? 'text-white/35' : 'text-gray-400'}`}>{t.subtitle}</div>
              </div>
            </div>
            <div className="flex items-center gap-1">
              {/* Lang selector */}
              <div className="flex gap-0.5">
                {LANGS.map((l) => (
                  <button key={l.code} onClick={() => setLang(l.code)}
                    className={`w-7 h-6 rounded-lg text-[10px] font-bold transition-all ${
                      lang === l.code
                        ? 'bg-[#00d4ff] text-[#080e1a]'
                        : isDark ? 'text-white/30 hover:text-white/60 hover:bg-white/8' : 'text-gray-400 hover:text-gray-600 hover:bg-black/5'
                    }`}>{l.label}</button>
                ))}
              </div>
              <div className={`w-px h-4 mx-1 ${isDark ? 'bg-white/10' : 'bg-gray-200'}`} />
              <button onClick={() => { setTtsOn((v) => !v); if (ttsOn) stopAudio(); }}
                className={`p-1.5 rounded-lg transition-colors ${ttsOn ? 'text-[#00d4ff]' : isDark ? 'text-white/25' : 'text-gray-300'} ${isDark ? 'hover:bg-white/8' : 'hover:bg-black/5'}`}>
                {ttsOn ? <Volume2 size={15} /> : <VolumeX size={15} />}
              </button>
              <button onClick={() => setOpen(false)}
                className={`p-1.5 rounded-lg transition-colors ${isDark ? 'text-white/35 hover:bg-white/8' : 'text-gray-400 hover:bg-black/5'}`}>
                <X size={15} />
              </button>
            </div>
          </div>

          {/* ── Role selector — no overflow-x-auto, wraps instead ── */}
          <div className={`flex-none px-3 py-2 border-b ${divider} flex flex-wrap gap-1`}>
            {ROLES.map((r) => {
              const RoleIcon = ROLE_ICONS[r];
              return (
                <button key={r} onClick={() => setRole(r)}
                  className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold transition-all whitespace-nowrap ${
                    role === r
                      ? 'bg-[#00d4ff] text-[#080e1a] shadow-[0_0_8px_rgba(0,212,255,0.35)]'
                      : isDark ? 'bg-white/6 text-white/45 hover:bg-white/12' : 'bg-black/5 text-gray-500 hover:bg-black/8'
                  }`}>
                  <RoleIcon size={11} strokeWidth={2} />
                  {t.roles[r]}
                </button>
              );
            })}
          </div>

          {/* ── Messages — ONLY scrollable element ── */}
          <div className="flex-1 min-h-0 overflow-y-auto overflow-x-hidden px-3 py-3 space-y-2.5 scrollbar-thin">
            {messages.map((m, i) => <Bubble key={i} msg={m} isDark={isDark} isRtl={isRtl} />)}
            {loading && <TypingDots isDark={isDark} />}
            <div ref={bottomRef} />
          </div>

          {/* ── Input ── */}
          <div className={`flex-none px-3 py-3 border-t ${divider}`}>
            <div className={`flex items-end gap-2 rounded-2xl px-3 py-2 ${inputWrap}`}>
              <textarea
                rows={1}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKey}
                dir={isRtl ? 'rtl' : 'ltr'}
                placeholder={listening ? t.listening : t.placeholder}
                className={`flex-1 resize-none bg-transparent text-sm outline-none leading-relaxed ${
                  isDark ? 'text-white placeholder-white/20' : 'text-gray-900 placeholder-gray-400'
                }`}
                style={{ maxHeight: 72 }}
              />
              {sttSupported && (
                <button onClick={toggleListening}
                  className={`flex-none p-1.5 rounded-xl transition-all ${
                    listening ? 'bg-red-500 text-white animate-pulse' : isDark ? 'text-white/35 hover:bg-white/10' : 'text-gray-400 hover:bg-black/5'
                  }`}>
                  {listening ? <MicOff size={15} /> : <Mic size={15} />}
                </button>
              )}
              <button onClick={send} disabled={!input.trim() || loading}
                className={`flex-none p-1.5 rounded-xl transition-all ${
                  input.trim() && !loading
                    ? 'bg-[#00d4ff] text-[#080e1a] hover:bg-[#00c4ef] shadow-[0_0_10px_rgba(0,212,255,0.4)]'
                    : isDark ? 'bg-white/5 text-white/15' : 'bg-black/5 text-gray-300'
                }`}>
                <Send size={15} />
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
