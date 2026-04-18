// ThreeBackground.jsx — GabèsEye Environmental Intelligence Platform
// Dark / Light theme aware — all environmental elements preserved

import React, { useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Points, PointMaterial } from '@react-three/drei';
import * as THREE from 'three';

// ─── PALETTES ──────────────────────────────────────────────────────────────────
const DARK = {
  bg:         '#080e1a',
  air:        '#06B6D4',
  water:      '#3B82F6',
  soil:       '#10B981',
  pollution:  '#F59E0B',
  alert:      '#EF4444',
  drone:      '#22D3EE',
  gridA:      '#0F3020',
  gridB:      '#081A10',
  fogNear:    12,
  fogFar:     50,
  ambient:    0.15,
  light1:     2.0,
  light2:     1.8,
  opacity:    { air: 0.38, water: 0.32, soil: 0.30 },
  blending:   THREE.AdditiveBlending,
  terrainOp:  0.55,
};

const LIGHT = {
  bg:         '#EFF6FF',
  air:        '#0891B2',
  water:      '#2563EB',
  soil:       '#059669',
  pollution:  '#D97706',
  alert:      '#DC2626',
  drone:      '#0284C7',
  gridA:      '#BFDBFE',
  gridB:      '#DBEAFE',
  fogNear:    15,
  fogFar:     55,
  ambient:    1.2,
  light1:     1.0,
  light2:     0.8,
  opacity:    { air: 0.55, water: 0.50, soil: 0.45 },
  blending:   THREE.NormalBlending,
  terrainOp:  0.40,
};

// ─── ENVIRONMENTAL PARTICLE LAYER ──────────────────────────────────────────────
const EnvLayer = ({ count, color, yBand, size, flowSpeed, windDrift, pulse, opacity, blending }) => {
  const ref = useRef();
  const [origins, phases] = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const ph  = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      pos[i*3]   = (Math.random() - 0.5) * 60;
      pos[i*3+1] = (Math.random() - 0.5) * 4 + yBand;
      pos[i*3+2] = (Math.random() - 0.5) * 30;
      ph[i] = Math.random() * Math.PI * 2;
    }
    return [pos, ph];
  }, [count, yBand]);

  useFrame(({ clock }) => {
    if (!ref.current) return;
    const t = clock.getElapsedTime();
    const attr = ref.current.geometry.attributes.position;
    for (let i = 0; i < count; i++) {
      const i3 = i * 3;
      const x0 = origins[i3], y0 = origins[i3+1], z0 = origins[i3+2];
      const ph = phases[i];
      let x = x0 + t * windDrift * (0.8 + ph * 0.4);
      x = ((x + 30) % 60) - 30;
      const y = y0
        + Math.sin(t * flowSpeed + ph) * pulse
        + Math.sin(t * flowSpeed * 0.4 + x0 * 0.08) * pulse * 0.5;
      attr.array[i3]   = x;
      attr.array[i3+1] = y;
      attr.array[i3+2] = z0;
    }
    attr.needsUpdate = true;
  });

  return (
    <Points ref={ref}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" count={count} array={origins} itemSize={3} />
      </bufferGeometry>
      <PointMaterial transparent size={size} sizeAttenuation color={color} depthWrite={false} opacity={opacity} blending={blending} />
    </Points>
  );
};

// ─── POLLUTION PLUME ───────────────────────────────────────────────────────────
const PollutionPlume = ({ origin, color, rise = 10, spread = 2.5, intensity = 1.0, blending }) => {
  const ref = useRef();
  const COUNT = 300;
  const [base, ph] = useMemo(() => {
    const b = new Float32Array(COUNT * 3);
    const p = new Float32Array(COUNT);
    for (let i = 0; i < COUNT; i++) {
      p[i] = Math.random();
      b[i*3] = origin[0]; b[i*3+1] = origin[1]; b[i*3+2] = origin[2];
    }
    return [b, p];
  }, [origin]);

  useFrame(({ clock }) => {
    if (!ref.current) return;
    const t = clock.getElapsedTime();
    const attr = ref.current.geometry.attributes.position;
    for (let i = 0; i < COUNT; i++) {
      const life = ((t * 0.35 + ph[i]) % 1);
      const curl = life * life;
      attr.array[i*3]   = origin[0] + Math.sin(t * 0.6 + ph[i] * 6.28) * curl * spread;
      attr.array[i*3+1] = origin[1] + life * rise;
      attr.array[i*3+2] = origin[2] + Math.cos(t * 0.5 + ph[i] * 6.28) * curl * spread;
    }
    attr.needsUpdate = true;
  });

  return (
    <Points ref={ref}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" count={COUNT} array={base} itemSize={3} />
      </bufferGeometry>
      <PointMaterial transparent size={0.09} sizeAttenuation color={color} depthWrite={false} opacity={0.45 * intensity} blending={blending} />
    </Points>
  );
};

// ─── SCAN RING ─────────────────────────────────────────────────────────────────
const ScanRing = ({ position, color, speed = 1, delay = 0 }) => {
  const ref = useRef();
  useFrame(({ clock }) => {
    if (!ref.current) return;
    const phase = ((clock.getElapsedTime() * speed + delay) % 4) / 4;
    const s = phase * 8 + 0.3;
    ref.current.scale.set(s, 1, s);
    ref.current.material.opacity = Math.max(0, 0.5 * (1 - phase));
  });
  return (
    <mesh ref={ref} position={position} rotation={[-Math.PI / 2, 0, 0]}>
      <ringGeometry args={[0.45, 0.55, 48]} />
      <meshBasicMaterial color={color} transparent opacity={0.5} side={THREE.DoubleSide} />
    </mesh>
  );
};

// ─── DRONE "Unité Horizon" ─────────────────────────────────────────────────────
const Drone = ({ P }) => {
  const bodyRef  = useRef();
  const beamRef  = useRef();
  const lightRef = useRef();

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (bodyRef.current) {
      bodyRef.current.position.x = Math.sin(t * 0.12) * 14;
      bodyRef.current.position.z = Math.sin(t * 0.08) * Math.cos(t * 0.05) * 10;
      bodyRef.current.position.y = 6.5 + Math.sin(t * 0.6) * 0.4;
      bodyRef.current.rotation.z = Math.sin(t * 0.12) * 0.2;
      bodyRef.current.rotation.x = Math.cos(t * 0.08) * 0.1;
    }
    if (beamRef.current) beamRef.current.rotation.y = t * 1.8;
    if (lightRef.current) lightRef.current.intensity = 1.5 + Math.sin(t * 3) * 0.4;
  });

  return (
    <group ref={bodyRef}>
      <mesh>
        <octahedronGeometry args={[0.28, 0]} />
        <meshStandardMaterial color={P.drone} emissive={P.drone} emissiveIntensity={1.2} wireframe />
      </mesh>
      <mesh rotation={[Math.PI/2, 0, 0]}>
        <torusGeometry args={[0.38, 0.025, 8, 32]} />
        <meshStandardMaterial color={P.drone} emissive={P.drone} emissiveIntensity={0.9} />
      </mesh>
      {[0, Math.PI/2, Math.PI, Math.PI*3/2].map((a, i) => (
        <group key={i} rotation={[0, a, 0]}>
          <mesh position={[0.55, 0, 0]}>
            <boxGeometry args={[0.7, 0.018, 0.045]} />
            <meshStandardMaterial color={P.soil} emissive={P.soil} emissiveIntensity={0.6} />
          </mesh>
          <mesh position={[0.95, 0, 0]} rotation={[Math.PI/2, 0, 0]}>
            <circleGeometry args={[0.22, 12]} />
            <meshBasicMaterial color={P.air} transparent opacity={0.15} side={THREE.DoubleSide} />
          </mesh>
        </group>
      ))}
      <group ref={beamRef} position={[0, -0.3, 0]}>
        <mesh>
          <coneGeometry args={[1.5, 5, 6, 1, true]} />
          <meshBasicMaterial color={P.air} transparent opacity={0.06} side={THREE.DoubleSide} />
        </mesh>
        <mesh>
          <coneGeometry args={[0.3, 5, 6, 1, true]} />
          <meshBasicMaterial color={P.air} transparent opacity={0.12} side={THREE.DoubleSide} />
        </mesh>
      </group>
      <pointLight ref={lightRef} color={P.drone} intensity={1.5} distance={10} decay={2} />
    </group>
  );
};

// ─── MONITORING NODES ──────────────────────────────────────────────────────────
const MonitoringNodes = ({ P }) => {
  const NODES = useMemo(() => [
    { pos: [-10, -5.5, -6], colorKey: 'air'       },
    { pos: [  7, -5.5,  4], colorKey: 'water'     },
    { pos: [  1, -5.5, -9], colorKey: 'soil'      },
    { pos: [ -6, -5.5,  7], colorKey: 'pollution' },
    { pos: [ 12, -5.5, -4], colorKey: 'air'       },
    { pos: [ -2, -5.5, 10], colorKey: 'water'     },
    { pos: [  5, -5.5, -6], colorKey: 'alert'     },
  ], []);

  const refs = useRef(NODES.map(() => React.createRef()));

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    refs.current.forEach((r, i) => {
      if (r.current) r.current.material.emissiveIntensity = 0.5 + Math.sin(t * 1.8 + i * 1.1) * 0.4;
    });
  });

  return (
    <group>
      {NODES.map((n, i) => {
        const col = P[n.colorKey];
        return (
          <group key={i} position={n.pos}>
            <mesh ref={refs.current[i]}>
              <sphereGeometry args={[0.13, 10, 10]} />
              <meshStandardMaterial color={col} emissive={col} emissiveIntensity={0.8} />
            </mesh>
            <mesh position={[0, 0.35, 0]}>
              <cylinderGeometry args={[0.015, 0.015, 0.7, 6]} />
              <meshStandardMaterial color={col} emissive={col} emissiveIntensity={0.5} />
            </mesh>
          </group>
        );
      })}
    </group>
  );
};

// ─── TERRAIN ───────────────────────────────────────────────────────────────────
const Terrain = ({ terrainOp }) => {
  const ref = useRef();
  const geo = useMemo(() => {
    const g = new THREE.PlaneGeometry(70, 50, 90, 70);
    const pos = g.attributes.position.array;
    const col = new Float32Array(pos.length);
    for (let i = 0; i < pos.length / 3; i++) {
      const x = pos[i*3], z = pos[i*3+2];
      const h = Math.sin(x * 0.08) * Math.cos(z * 0.12) * 1.8
              + Math.sin(x * 0.25 + z * 0.18) * 0.6
              + (Math.random() - 0.5) * 0.25;
      pos[i*3+1] = h;
      const pf = Math.max(0, Math.sin((x + 4) * 0.18) * Math.cos(z * 0.12));
      const hf = Math.max(0, Math.cos(x * 0.1) * Math.sin((z - 4) * 0.13));
      col[i*3]   = pf * 0.7 + 0.06;
      col[i*3+1] = hf * 0.6 + 0.12;
      col[i*3+2] = 0.08 + Math.abs(h) * 0.04;
    }
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    g.computeVertexNormals();
    return g;
  }, []);

  useFrame(({ clock }) => {
    if (ref.current) ref.current.rotation.z = Math.sin(clock.getElapsedTime() * 0.04) * 0.015;
  });

  return (
    <mesh ref={ref} geometry={geo} rotation={[-Math.PI / 2.6, 0, 0.15]} position={[0, -9, 6]}>
      <meshStandardMaterial vertexColors transparent opacity={terrainOp} roughness={0.9} />
    </mesh>
  );
};

// ─── TELEMETRY ARC ─────────────────────────────────────────────────────────────
const TelemetryLine = ({ from, to, color }) => {
  const ref = useRef();
  useFrame(({ clock }) => {
    if (ref.current) ref.current.material.opacity = 0.08 + Math.abs(Math.sin(clock.getElapsedTime() * 1.2)) * 0.15;
  });
  const pts = useMemo(() => [
    new THREE.Vector3(...from),
    new THREE.Vector3((from[0]+to[0])/2, Math.max(from[1], to[1]) + 3, (from[2]+to[2])/2),
    new THREE.Vector3(...to),
  ], [from, to]);
  const geom = useMemo(() => {
    const g = new THREE.BufferGeometry();
    g.setFromPoints(new THREE.CatmullRomCurve3(pts).getPoints(20));
    return g;
  }, [pts]);
  return (
    <line ref={ref} geometry={geom}>
      <lineBasicMaterial color={color} transparent opacity={0.15} />
    </line>
  );
};

// ─── ROOT ──────────────────────────────────────────────────────────────────────
const ThreeBackground = ({ theme }) => {
  const P = theme === 'dark' ? DARK : LIGHT;

  return (
    <div
      className="fixed inset-0 z-0 pointer-events-none transition-colors duration-700"
      style={{ background: P.bg }}
    >
      <Canvas camera={{ position: [0, 6, 22], fov: 48 }} dpr={[1, 1.5]} gl={{ antialias: true, alpha: false }}>
        <color attach="background" args={[P.bg]} />
        <fog attach="fog" args={[P.bg, P.fogNear, P.fogFar]} />

        <ambientLight intensity={P.ambient} />
        <pointLight position={[0, 12, 5]}   intensity={P.light1}       color={P.drone}     />
        <pointLight position={[-14, 4, -8]} intensity={P.light2}       color={P.pollution} />
        <pointLight position={[12, 3, 10]}  intensity={P.light1 * 0.6} color={P.soil}      />
        <pointLight position={[0, -2, -10]} intensity={P.light2 * 0.5} color={P.water}     />

        <Terrain terrainOp={P.terrainOp} />
        <gridHelper args={[120, 60, P.gridA, P.gridB]} position={[0, -10, 0]} />

        <EnvLayer count={900}  color={P.air}   yBand={7}  size={0.032} flowSpeed={0.45} windDrift={0.9}  pulse={1.1}  opacity={P.opacity.air}   blending={P.blending} />
        <EnvLayer count={1100} color={P.water} yBand={1}  size={0.042} flowSpeed={0.75} windDrift={0.25} pulse={0.65} opacity={P.opacity.water} blending={P.blending} />
        <EnvLayer count={1400} color={P.soil}  yBand={-5} size={0.055} flowSpeed={0.22} windDrift={0.07} pulse={0.32} opacity={P.opacity.soil}  blending={P.blending} />

        <PollutionPlume origin={[4, -6, 3]}   color={P.pollution} rise={12} spread={3.0} intensity={1.0}  blending={P.blending} />
        <PollutionPlume origin={[-6, -6, -2]} color={P.pollution} rise={9}  spread={2.0} intensity={0.75} blending={P.blending} />
        <PollutionPlume origin={[2, -6, -5]}  color={P.alert}     rise={7}  spread={1.5} intensity={0.55} blending={P.blending} />

        <ScanRing position={[4, -6.2, 3]}   color={P.pollution} speed={0.9} delay={0}   />
        <ScanRing position={[-6, -6.2, -2]} color={P.pollution} speed={0.7} delay={1.5} />
        <ScanRing position={[2, -6.2, -5]}  color={P.alert}     speed={1.2} delay={0.8} />

        <Drone P={P} />
        <MonitoringNodes P={P} />

        <TelemetryLine from={[-10, -5.5, -6]} to={[7, -5.5, 4]}   color={P.air}       />
        <TelemetryLine from={[7, -5.5, 4]}    to={[1, -5.5, -9]}  color={P.water}     />
        <TelemetryLine from={[1, -5.5, -9]}   to={[-6, -5.5, 7]}  color={P.soil}      />
        <TelemetryLine from={[-6, -5.5, 7]}   to={[5, -5.5, -6]}  color={P.pollution} />
        <TelemetryLine from={[5, -5.5, -6]}   to={[12, -5.5, -4]} color={P.alert}     />
      </Canvas>
    </div>
  );
};

export default ThreeBackground;