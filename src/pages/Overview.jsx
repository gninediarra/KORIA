import React, { useRef, useContext } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float, PerspectiveCamera } from '@react-three/drei';
import { 
  Brain, 
  RefreshCcw, 
  Wind, 
  Droplets, 
  Trees, 
  Search, 
  AlertTriangle, 
  Eye, 
  TrendingUp,
  Activity,
  ArrowRight,
  ShieldCheck,
  Zap
} from 'lucide-react';
import { ThemeContext } from '../App';

const DronePreview = ({ isDark }) => {
  const droneRef = useRef();
  useFrame((state) => {
    if (droneRef.current) {
      droneRef.current.rotation.y = state.clock.getElapsedTime() * 0.4;
      droneRef.current.position.y = Math.sin(state.clock.getElapsedTime() * 0.8) * 0.15;
    }
  });

  return (
    <group ref={droneRef}>
      {/* Main Body */}
      <mesh castShadow>
        <boxGeometry args={[1.3, 0.22, 0.7]} />
        <meshStandardMaterial color={isDark ? "#f8fafc" : "#1e293b"} metalness={0.6} roughness={0.1} />
      </mesh>
      
      {/* Central Core */}
      <mesh position={[0, 0.16, 0]}>
        <boxGeometry args={[0.55, 0.12, 0.45]} />
        <meshStandardMaterial color="#00d4ff" emissive="#00d4ff" emissiveIntensity={0.5} />
      </mesh>

      {/* Navigation Lights */}
      <mesh position={[0.45, 0, 0.38]}>
        <sphereGeometry args={[0.07, 16, 16]} />
        <meshBasicMaterial color="#00d4ff" />
      </mesh>
      <mesh position={[-0.45, 0, 0.38]}>
        <sphereGeometry args={[0.07, 16, 16]} />
        <meshBasicMaterial color="#00d4ff" />
      </mesh>

      {/* Motor Hubs */}
      {[[-0.55, 0.35], [0.55, 0.35], [-0.55, -0.35], [0.55, -0.35]].map((pos, i) => (
        <group key={i} position={[pos[0], 0, pos[1]]}>
          <mesh>
            <cylinderGeometry args={[0.1, 0.12, 0.15, 16]} />
            <meshStandardMaterial color={isDark ? "#334155" : "#94a3b8"} />
          </mesh>
          <mesh position={[0, 0.1, 0]}>
            <cylinderGeometry args={[0.35, 0.35, 0.01, 32]} />
            <meshStandardMaterial color="#ffffff" transparent opacity={0.15} />
          </mesh>
        </group>
      ))}
    </group>
  );
};

const DroneCard = ({ isDark }) => (
  <div className={`backdrop-blur-3xl border rounded-[48px] overflow-hidden group shadow-2xl transition-all duration-700 ${
    isDark ? 'bg-white/[0.02] border-white/10 shadow-[0_0_50px_rgba(0,212,255,0.05)]' : 'bg-white border-gray-200 shadow-gray-200/50'
  }`}>
    <div className="grid lg:grid-cols-2 items-center">
      {/* 3D Scene Container */}
      <div className={`h-[450px] relative border-r transition-colors duration-700 ${
        isDark ? 'bg-gradient-to-br from-[#00d4ff]/10 via-transparent to-transparent border-white/5' : 'bg-gradient-to-br from-[#00d4ff]/5 to-transparent border-gray-100'
      }`}>
        <Canvas>
          <PerspectiveCamera makeDefault position={[0, 0, 5]} fov={40} />
          <ambientLight intensity={isDark ? 0.7 : 1} />
          <pointLight position={[10, 10, 10]} intensity={1.5} />
          <pointLight position={[-10, -10, -10]} intensity={0.5} color="#00d4ff" />
          <spotLight position={[0, 5, 0]} intensity={1} color="#ffffff" angle={0.5} />
          <Float speed={1.5} rotationIntensity={0.5} floatIntensity={0.5}>
            <DronePreview isDark={isDark} />
          </Float>
        </Canvas>
        <div className="absolute bottom-8 left-8">
          <div className="flex items-center gap-2 px-3 py-1 bg-[#00d4ff]/20 border border-[#00d4ff]/30 rounded-full text-[#00d4ff] text-[10px] font-bold tracking-widest uppercase">
            <Zap size={12} /> Active Inspection
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-12">
        <div className="flex items-center gap-3 text-[#00d4ff] mb-6 uppercase tracking-widest text-[10px] font-bold">
          <ShieldCheck size={16} /> Drone de Surveillance Autonome
        </div>
        <h3 className={`text-3xl font-bold mb-6 ${isDark ? 'text-white' : 'text-gray-900'}`}>Unité d'Inspection Horizon</h3>
        <p className={`font-light leading-relaxed mb-8 ${isDark ? 'text-blue-100/60' : 'text-gray-600'}`}>
          Le drone GabèsEye n'est pas un simple outil de capture. C'est un laboratoire volant capable de cartographier en temps réel les zones industrielles et agricoles de Gabès.
        </p>
        <ul className="space-y-4 mb-10">
          {[
            { icon: Search, text: "Cartographie thermique des sols" },
            { icon: Activity, text: "Analyse spectrale de la qualité de l'air" },
            { icon: AlertTriangle, text: "Détection précoce des fuites industrielles" }
          ].map((item, i) => (
            <li key={i} className={`flex items-center gap-3 text-sm ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>
              <item.icon size={16} className="text-[#00d4ff]" />
              {item.text}
            </li>
          ))}
        </ul>
        <button className={`flex items-center gap-2 font-bold transition-colors group ${isDark ? 'text-white hover:text-[#00d4ff]' : 'text-gray-900 hover:text-[#00d4ff]'}`}>
          Spécifications techniques <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
        </button>
      </div>
    </div>
  </div>
);

const Card = ({ title, children, icon: Icon, iconColor = "text-[#00d4ff]", isDark }) => (
  <div className={`backdrop-blur-xl border rounded-[32px] p-8 shadow-2xl transition-all duration-500 group ${
    isDark 
      ? 'bg-white/[0.03] border-white/10 hover:bg-white/[0.06]' 
      : 'bg-white border-gray-100 hover:border-gray-200 hover:shadow-gray-200/50'
  }`}>
    <div className="flex items-center gap-5 mb-6">
      {Icon && (
        <div className={`p-3 rounded-2xl border transition-transform duration-500 group-hover:scale-110 ${
          isDark ? 'bg-white/5 border-white/10 ' + iconColor : 'bg-gray-50 border-gray-100 ' + iconColor
        }`}>
          <Icon size={28} strokeWidth={1.5} />
        </div>
      )}
      <h3 className={`text-2xl font-semibold tracking-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>{title}</h3>
    </div>
    <div className={`leading-relaxed font-light ${isDark ? 'text-blue-50/60' : 'text-gray-600'}`}>
      {children}
    </div>
  </div>
);

const SectionTitle = ({ title, subtitle, isDark }) => (
  <div className="mb-16">
    <div className="flex items-center gap-3 mb-4">
      <div className="h-px w-8 bg-[#00d4ff]"></div>
      <p className="text-[#00d4ff] font-bold tracking-[0.2em] uppercase text-xs">{subtitle}</p>
    </div>
    <h2 className={`text-4xl md:text-6xl font-bold tracking-tight leading-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>
      {title}
    </h2>
  </div>
);

const Overview = () => {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  return (
    <div className="max-w-7xl mx-auto px-8 py-24 relative">
      {/* Hero Section */}
      <header className="mb-40 text-center relative">
        <div className={`absolute top-0 left-1/2 -translate-x-1/2 w-96 h-96 blur-[120px] rounded-full -z-10 ${isDark ? 'bg-[#00d4ff]/10' : 'bg-[#00d4ff]/5'}`}></div>
        <div className={`inline-flex items-center gap-2 px-4 py-2 backdrop-blur-md border rounded-full font-bold text-[10px] tracking-[0.2em] mb-8 uppercase transition-colors duration-700 ${
          isDark ? 'bg-white/5 border-white/10 text-[#00d4ff]' : 'bg-white border-gray-200 text-[#00d4ff] shadow-sm'
        }`}>
          <Activity size={14} /> System Live Monitoring
        </div>
        <h1 className={`text-7xl md:text-9xl font-bold mb-10 tracking-tighter leading-none transition-colors duration-700 ${isDark ? 'text-white' : 'text-gray-900'}`}>
          Gabès<span className="text-[#00d4ff]">Eye</span>
        </h1>
        <p className={`text-xl md:text-2xl max-w-3xl mx-auto font-light leading-relaxed transition-colors duration-700 ${isDark ? 'text-blue-100/50' : 'text-gray-500'}`}>
          Une plateforme d'intelligence environnementale conçue pour restaurer l'équilibre systémique de la région de Gabès.
        </p>
      </header>

      {/* 🧠 Le problème */}
      <section className="mb-40">
        <SectionTitle title="L'urgence d'une vision systémique" subtitle="Diagnostic" isDark={isDark} />
        <div className="grid md:grid-cols-2 gap-8">
          <Card title="Déséquilibre Global" icon={Brain} iconColor="text-blue-400" isDark={isDark}>
            Gabès n'est pas confrontée à un problème isolé. Son système environnemental est en train de perdre son équilibre vital.
            <div className={`mt-6 space-y-3 border-t pt-6 ${isDark ? 'border-white/5' : 'border-gray-100'}`}>
              <div className="flex items-center gap-3 text-sm">
                <div className="w-1.5 h-1.5 rounded-full bg-[#00d4ff]"></div>
                <span>Interdépendance totale Eau / Sol / Air</span>
              </div>
              <div className={`flex items-center gap-3 text-sm ${isDark ? 'text-blue-100/40' : 'text-gray-400'}`}>
                <div className="w-1.5 h-1.5 rounded-full bg-blue-400/50"></div>
                <span>Dégradation par effet domino</span>
              </div>
            </div>
          </Card>
          <Card title="Boucles de Rétroaction" icon={RefreshCcw} iconColor="text-amber-400" isDark={isDark}>
            Les processus de dégradation s'auto-alimentent. Le vrai défi réside dans la compréhension de ces boucles complexes plutôt que dans le traitement des symptômes isolés.
          </Card>
        </div>
      </section>

      {/* 🔬 Mode Feynman */}
      <section className="mb-40">
        <SectionTitle title="Comprendre le métabolisme" subtitle="Analogie" isDark={isDark} />
        <div className={`backdrop-blur-3xl border rounded-[48px] p-16 shadow-inner relative overflow-hidden transition-all duration-700 ${
          isDark ? 'bg-gradient-to-br from-white/[0.02] to-transparent border-white/10' : 'bg-white border-gray-100 shadow-gray-200/50'
        }`}>
          <div className={`absolute top-0 right-0 w-64 h-64 blur-[100px] ${isDark ? 'bg-blue-500/5' : 'bg-blue-500/[0.02]'}`}></div>
          <p className={`text-3xl font-light mb-20 text-center leading-tight max-w-4xl mx-auto ${isDark ? 'text-blue-50' : 'text-gray-800'}`}>
            "Imaginez Gabès comme un <span className="text-[#00d4ff] font-medium italic">corps humain</span> dont les fonctions vitales sont intimement liées."
          </p>
          <div className="grid md:grid-cols-3 gap-16">
            <div className="text-center group">
              <div className={`w-24 h-24 rounded-[32px] flex items-center justify-center mx-auto mb-8 border transition-all duration-500 ${
                isDark 
                  ? 'bg-white/5 border-white/10 text-white group-hover:bg-[#00d4ff]/10 group-hover:border-[#00d4ff]/30' 
                  : 'bg-gray-50 border-gray-100 text-gray-700 group-hover:bg-white group-hover:shadow-lg group-hover:text-[#00d4ff]'
              }`}>
                <Wind size={40} strokeWidth={1} />
              </div>
              <h4 className={`font-semibold text-xl mb-3 tracking-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>L'Air</h4>
              <p className={`font-light uppercase tracking-widest text-[10px] ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>Système Respiratoire</p>
            </div>
            <div className="text-center group">
              <div className={`w-24 h-24 rounded-[32px] flex items-center justify-center mx-auto mb-8 border transition-all duration-500 ${
                isDark 
                  ? 'bg-white/5 border-white/10 text-white group-hover:bg-blue-500/10 group-hover:border-blue-500/30' 
                  : 'bg-gray-50 border-gray-100 text-gray-700 group-hover:bg-white group-hover:shadow-lg group-hover:text-blue-600'
              }`}>
                <Droplets size={40} strokeWidth={1} />
              </div>
              <h4 className={`font-semibold text-xl mb-3 tracking-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>L'Eau</h4>
              <p className={`font-light uppercase tracking-widest text-[10px] ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>Système Circulatoire</p>
            </div>
            <div className="text-center group">
              <div className={`w-24 h-24 rounded-[32px] flex items-center justify-center mx-auto mb-8 border transition-all duration-500 ${
                isDark 
                  ? 'bg-white/5 border-white/10 text-white group-hover:bg-amber-500/10 group-hover:border-amber-500/30' 
                  : 'bg-gray-50 border-gray-100 text-gray-700 group-hover:bg-white group-hover:shadow-lg group-hover:text-amber-500'
              }`}>
                <Trees size={40} strokeWidth={1} />
              </div>
              <h4 className={`font-semibold text-xl mb-3 tracking-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>Le Sol</h4>
              <p className={`font-light uppercase tracking-widest text-[10px] ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>Fonctions Vitales</p>
            </div>
          </div>
        </div>
      </section>

      {/* 🔁 Changement de paradigme */}
      <section className="pb-32">
        <SectionTitle title="Vers un nouvel équilibre" subtitle="Vision" isDark={isDark} />
        <div className="mb-20">
          <DroneCard isDark={isDark} />
        </div>
        <div className="grid md:grid-cols-2 gap-16 items-center">
          <div className="space-y-8">
            <div className={`p-8 border rounded-[32px] transition-colors duration-700 ${
              isDark ? 'bg-white/[0.02] border-white/5' : 'bg-white border-gray-100 shadow-sm'
            }`}>
              <div className="flex items-center gap-3 text-red-400 mb-6 uppercase tracking-widest text-[10px] font-bold">
                <TrendingUp className="rotate-180" size={14} /> Héritage Actuel
              </div>
              <ul className={`space-y-4 font-light ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>
                <li className="flex items-center gap-3">
                  <div className="w-1 h-1 rounded-full bg-red-400/60"></div>
                  Données fragmentées et isolées
                </li>
                <li className="flex items-center gap-3">
                  <div className="w-1 h-1 rounded-full bg-red-400/60"></div>
                  Prise de décision réactive
                </li>
              </ul>
            </div>
            <div className={`p-8 border rounded-[32px] transition-colors duration-700 ${
              isDark ? 'bg-[#00d4ff]/5 border-[#00d4ff]/10' : 'bg-[#00d4ff]/5 border-[#00d4ff]/10 shadow-sm'
            }`}>
              <div className="flex items-center gap-3 text-[#00d4ff] mb-6 uppercase tracking-widest text-[10px] font-bold">
                <TrendingUp size={14} /> Ère GabèsEye
              </div>
              <ul className={`space-y-4 font-light ${isDark ? 'text-blue-100/80' : 'text-[#00d4ff]/80'}`}>
                <li className="flex items-center gap-3">
                  <div className="w-1 h-1 rounded-full bg-[#00d4ff]"></div>
                  Intelligence systémique intégrée
                </li>
                <li className="flex items-center gap-3">
                  <div className="w-1 h-1 rounded-full bg-[#00d4ff]"></div>
                  Anticipation et proactivité
                </li>
              </ul>
            </div>
          </div>
          <div className="md:pl-12 text-right">
            <button className={`group relative px-12 py-6 font-bold rounded-full text-lg overflow-hidden transition-all hover:scale-105 active:scale-95 shadow-2xl ${
              isDark ? 'bg-white text-gray-950' : 'bg-gray-900 text-white'
            }`}>
              <span className="relative z-10 flex items-center gap-3">
                Explorer <ArrowRight size={20} />
              </span>
              <div className="absolute inset-0 bg-[#00d4ff] translate-y-full group-hover:translate-y-0 transition-transform duration-500"></div>
            </button>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Overview;