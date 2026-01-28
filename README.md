
# 👻 CyberGhost OSINT v5.0 
### Advanced Open Source Intelligence Platform by Leonardo Pereira Pinheiro (CyberGhost)

<div align="center">
  <img src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExcmU0cGUyd292cWE4OXNveGR2bzZwdnAydHo3cm9rYWprZDloY2ZlMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/4rZA5D22301iMgrUNd/giphy.gif" alt="Descrição da Imagem" width="800">
</div>


[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-green.svg)](https://opensource.org/licenses/GPL-3.0)
[![Open Source](https://img.shields.io/badge/Open%20Source-Yes-brightgreen.svg)](https://opensource.org/)
[![Maintenance](https://img.shields.io/badge/Maintained-Yes-success.svg)](https://github.com/CyberGhost-Leonardo/CyberGhost-OSINT)
[![GitHub stars](https://img.shields.io/github/stars/CyberGhost-Leonardo/CyberGhost-OSINT?style=social)](https://github.com/CyberGhost-Leonardo/CyberGhost-OSINT/stargazers)

---

## 🔬 Arquitetura Técnica e Metodologia

O projeto foi construído sobre quatro pilares fundamentais da segurança ofensiva:

1. **Information Gathering (Passive/Active):** Coleta de metadados, DNS Intelligence, subdomínios (via CT Logs e Bruteforce) e Service Fingerprinting.
2. **Attack Surface Analysis:** Identificação de ativos expostos e mapeamento de topologia de rede utilizando bibliotecas de baixo nível como `Scapy` e `Nmap`.
3. **AI-Driven Threat Intelligence:** Utilização de modelos NLP (Natural Language Processing) para análise de sensibilidade de dados e predição de vulnerabilidades baseada em heurísticas.
4. **Data Encryption & OpSec:** Implementação do **GhostCache**, um sistema de persistência encriptada para garantir a integridade e confidencialidade da inteligência coletada durante o engajamento.

## 🛠️ Stack Tecnológica

* **Engine:** Python 3.11 (Assíncrono com `AsyncIO` para alta performance).
* **Networking:** `Nmap`, `Scapy`, `DNSResolver`.
* **Inteligência Artificial:** `PyTorch`, `Transformers` (HuggingFace), `SpaCy`.
* **Data Science & Viz:** `Pandas`, `Plotly` (Visualização 3D), `NetworkX`.
* **Storage:** `Redis` para cache distribuído e `Fernet` (AES-128) para encriptação de cache local.
---

## 🚀 **Overview**

**CyberGhost OSINT** is a powerful, AI-powered Open Source Intelligence platform designed for cybersecurity professionals, researchers, and ethical hackers. This tool provides comprehensive reconnaissance capabilities with enterprise-grade features.

### **🎯 What is CyberGhost OSINT?**
A comprehensive OSINT (Open Source Intelligence) tool that combines traditional reconnaissance techniques with modern AI capabilities to provide deep insights into digital targets while maintaining ethical standards and legal compliance.

---

## ✨ **Features**

### **🔍 Advanced Reconnaissance**
| Feature | Description |
|---------|-------------|
| **Subdomain Enumeration** | Brute force, certificate transparency, DNS queries |
| **Port Scanning** | Advanced scanning with service detection |
| **Technology Fingerprinting** | Identify 1000+ technologies and frameworks |
| **SSL/TLS Analysis** | Certificate details, vulnerabilities, expiration |
| **WHOIS Intelligence** | Domain registration details and history |
| **DNS Intelligence** | Comprehensive DNS record analysis |
| **Web Content Analysis** | Metadata, emails, phone numbers extraction |

### **🤖 AI-Powered Intelligence**
| Feature | Description |
|---------|-------------|
| **Threat Prediction** | ML models predict potential attack vectors |
| **Sentiment Analysis** | Assess risk based on content analysis |
| **Anomaly Detection** | Identify suspicious patterns automatically |
| **Pattern Recognition** | Detect recurring attack patterns |
| **Automated Reporting** | AI-generated summaries and recommendations |
| **Entity Extraction** | Identify people, organizations, locations |

### **📊 Visualization & Reporting**
| Feature | Description |
|---------|-------------|
| **Interactive Dashboards** | Cyberpunk-themed HTML reports |
| **Network Graphs** | 3D visualization of relationships |
| **Threat Radars** | Visual risk assessment |
| **Heatmaps** | Port and vulnerability distribution |
| **Timeline Analysis** | Historical changes and events |
| **Multi-Format Export** | HTML, PDF, JSON, Markdown, LaTeX |

### **🔒 Security & Privacy**
| Feature | Description |
|---------|-------------|
| **Encrypted Cache** | Secure storage with auto-destruction |
| **Anonymization** | Automatic data protection |
| **Legal Compliance** | GDPR/LGPD ready features |
| **Proxy Support** | SOCKS5, HTTP, TOR integration |
| **Stealth Mode** | Low-detection operations |
| **Audit Logging** | Complete activity tracking |

---

## 📦 **Installation**

### **System Requirements**
- **OS**: Linux (recommended), macOS, Windows (WSL2)
- **Python**: 3.10 or higher
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 2GB free space
- **Internet**: Required for API integrations

### **Step-by-Step Installation**

#### **1. Clone Repository**
```bash
git clone https://github.com/CyberGhost-Leonardo/CyberGhost-OSINT.git
cd CyberGhost-OSINT
