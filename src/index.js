// src/index.js
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';           // ← este import es el que está fallando
import './styles.css';             // tu archivo de estilos

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);