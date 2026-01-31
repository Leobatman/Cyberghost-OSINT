#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║  ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ ██████╗ ███████╗███████╗████████╗║
║ ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║  ██║██╔═══██╗██╔════╝██╔════╝╚══██╔══╝║
║ ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████║██║   ██║███████╗███████╗   ██║   ║
║ ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║██║   ██║╚════██║╚════██║   ██║   ║
║ ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║  ██║╚██████╔╝███████║███████║   ██║   ║
║  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ║
║                                                                                    ║
║   CYBERGHOST OSINT v5.0 - Plataforma de Inteligência Cibernética                   ║
║   Desenvolvido por: Leonardo Pereira Pinheiro                                      ║
║   Código: Shadow Warrior | Alias: CyberGhost                                       ║
║   Licença: GPL-3.0 | Uso Ético e Legal Requerido                                   ║
║                                                                                    ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"""

# =============================================================================
# CONFIGURAÇÃO DO SISTEMA - CYBERGHOST EDITION
# =============================================================================
import asyncio
import aiohttp
import aiofiles
import sys
import os
import json
import logging
import hashlib
import pickle
import base64
import uuid
import secrets
import random
import string
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union
from pathlib import Path
from functools import wraps
from contextlib import asynccontextmanager
import warnings
warnings.filterwarnings('ignore')

# =============================================================================
# DEPENDÊNCIAS CORE - CYBERGHOST EDITION
# =============================================================================

# Lista de dependências necessárias
REQUIRED_DEPENDENCIES = {
    'aiohttp': 'aiohttp',
    'aiofiles': 'aiofiles',
    'beautifulsoup4': 'bs4',
    'requests': 'requests',
    'colorama': 'colorama',
    'tabulate': 'tabulate',
    'tqdm': 'tqdm',
    'pandas': 'pandas',
    'numpy': 'numpy',
    'dnspython': 'dns',
    'python-whois': 'whois',
    'builtwith': 'builtwith'
}

# Dependências opcionais
OPTIONAL_DEPENDENCIES = {
    'nmap': 'nmap',
    'scapy': 'scapy',
    'transformers': 'transformers',
    'torch': 'torch',
    'spacy': 'spacy',
    'nltk': 'nltk',
    'plotly': 'plotly',
    'matplotlib': 'matplotlib',
    'seaborn': 'seaborn',
    'networkx': 'nx',
    'redis': 'redis',
    'bcrypt': 'bcrypt',
    'cryptography': 'cryptography',
    'openai': 'openai',
    'shodan': 'shodan'
}

def check_dependencies():
    """Verifica e importa dependências"""
    missing_required = []
    missing_optional = []
    
    # Verifica dependências requeridas
    for pip_name, import_name in REQUIRED_DEPENDENCIES.items():
        try:
            __import__(import_name)
        except ImportError:
            missing_required.append(pip_name)
    
    # Verifica dependências opcionais
    for pip_name, import_name in OPTIONAL_DEPENDENCIES.items():
        try:
            __import__(import_name)
        except ImportError:
            missing_optional.append(pip_name)
    
    if missing_required:
        print(f"❌ Dependências obrigatórias ausentes:")
        for dep in missing_required:
            print(f"   - {dep}")
        print(f"\n🔧 Instale com: pip install {' '.join(missing_required)}")
        sys.exit(1)
    
    if missing_optional:
        print(f"⚠️  Dependências opcionais ausentes:")
        for dep in missing_optional:
            print(f"   - {dep}")
        print(f"\n💡 Recursos avançados podem não funcionar sem estas dependências")
    
    # Importa bibliotecas requeridas
    global BeautifulSoup, requests, colorama, tabulate, tqdm
    global pd, np, dns, whois, builtwith, Fore, Style, Back
    
    from colorama import Fore, Style, Back, init as colorama_init
    from bs4 import BeautifulSoup
    import requests
    from tabulate import tabulate
    from tqdm.auto import tqdm
    import pandas as pd
    import numpy as np
    import dns.resolver
    import dns.asyncresolver
    import builtwith
    
    # Tenta importar dependências opcionais
    global nmap, scapy, torch, transformers, spacy, plt, go, nx, openai, shodan
    global OPENAI_AVAILABLE, SHODAN_AVAILABLE
    
    OPENAI_AVAILABLE = False
    SHODAN_AVAILABLE = False
    
    try:
        import nmap
    except ImportError:
        nmap = None
    
    try:
        import scapy.all as scapy
    except ImportError:
        scapy = None
    
    try:
        import torch
        import transformers
        from transformers import pipeline
    except ImportError:
        torch = None
        transformers = None
    
    try:
        import spacy
    except ImportError:
        spacy = None
    
    try:
        import matplotlib.pyplot as plt
        import seaborn as sns
    except ImportError:
        plt = None
        sns = None
    
    try:
        import plotly.graph_objects as go
        import plotly.express as px
    except ImportError:
        go = None
        px = None
    
    try:
        import networkx as nx
    except ImportError:
        nx = None
    
    try:
        import openai
        from openai import AsyncOpenAI
        OPENAI_AVAILABLE = True
    except ImportError:
        openai = None
    
    try:
        import shodan
        SHODAN_AVAILABLE = True
    except ImportError:
        shodan = None

# Verifica dependências
check_dependencies()

# Inicializa colorama
colorama_init(autoreset=True)

# =============================================================================
# CONSTANTES E CONFIGURAÇÃO - CYBERGHOST THEME
# =============================================================================

class CyberGhostMode:
    """Modos de operação do CyberGhost"""
    STEALTH = "stealth"
    RECON = "reconnaissance"
    ASSAULT = "assault"
    DEFENSE = "defense"
    FORENSIC = "forensic"
    ACADEMIC = "academic"

class ThreatLevel:
    """Níveis de ameaça estilo militar"""
    CRITICAL = ("CRITICAL", 5, "🔴")
    HIGH = ("HIGH", 4, "🟠")
    MEDIUM = ("MEDIUM", 3, "🟡")
    LOW = ("LOW", 2, "🟢")
    INFO = ("INFO", 1, "🔵")
    
    def __init__(self, label, value, icon):
        self.label = label
        self.value = value
        self.icon = icon

# Configuração padrão CyberGhost
CYBERGHOST_CONFIG = {
    "version": "5.0",
    "author": "Leonardo Pereira Pinheiro",
    "alias": "CyberGhost",
    "codename": "Shadow Warrior",
    
    "operation": {
        "mode": "stealth",
        "max_threads": 10,
        "timeout": 45,
        "retries": 3,
        "user_agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 CyberGhost/5.0",
    },
    
    "modules": {
        "recon": {
            "subdomain_bruteforce": True,
            "port_scanning": True,
            "service_detection": True,
        },
        "intel": {
            "threat_intelligence": True
        },
        "analysis": {
            "ai_enhanced": True,
        },
        "reporting": {
            "generate_report": True,
            "export_formats": ["html", "json", "txt"],
        }
    },
    
    "security": {
        "anonymization": True,
        "legal_compliance": True
    }
}

# =============================================================================
# SISTEMA DE LOGGING HACKER-STYLE
# =============================================================================

class CyberGhostLogger:
    """Logger estilo hacker com cores e efeitos"""
    
    def __init__(self, name: str = "CyberGhost"):
        self.name = name
        self.session_id = str(uuid.uuid4())[:8]
        self.operation_start = datetime.now()
        
        # Setup logging
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)
        
        # Formato hacker
        formatter = logging.Formatter(
            f'{Fore.BLACK}[{Fore.GREEN}%(asctime)s{Fore.BLACK}]'
            f'[{Fore.CYAN}{name}{Fore.BLACK}]'
            f'[{Fore.YELLOW}%(levelname)s{Fore.BLACK}]'
            f' %(message)s{Style.RESET_ALL}',
            datefmt='%H:%M:%S'
        )
        
        # Handler para console
        console = logging.StreamHandler()
        console.setFormatter(formatter)
        console.setLevel(logging.INFO)
        
        # Handler para arquivo
        file_handler = logging.FileHandler(f'cyberghost_{self.session_id}.log')
        file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
        file_handler.setLevel(logging.DEBUG)
        
        self.logger.addHandler(console)
        self.logger.addHandler(file_handler)
        
        self._print_banner()
    
    def _print_banner(self):
        """Imprime banner do CyberGhost"""
        banner = f"""
{Fore.CYAN}╔══════════════════════════════════════════════════════════════════════════════════╗
║{Fore.GREEN}                                                                                    {Fore.CYAN}║
║{Fore.GREEN}  ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ ██████╗ ███████╗███████╗████████╗{Fore.CYAN}║
║{Fore.GREEN} ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║  ██║██╔═══██╗██╔════╝██╔════╝╚══██╔══╝{Fore.CYAN}║
║{Fore.GREEN} ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████║██║   ██║███████╗███████╗   ██║   {Fore.CYAN}║
║{Fore.GREEN} ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║██║   ██║╚════██║╚════██║   ██║   {Fore.CYAN}║
║{Fore.GREEN} ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║  ██║╚██████╔╝███████║███████║   ██║   {Fore.CYAN}║
║{Fore.GREEN}  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝   {Fore.CYAN}║
║{Fore.GREEN}                                                                                    {Fore.CYAN}║
║{Fore.YELLOW}                    CYBERGHOST OSINT v5.0 - Shadow Warrior Edition                 {Fore.CYAN}║
╚══════════════════════════════════════════════════════════════════════════════════╝{Style.RESET_ALL}
        """
        
        print(banner)
        print(f"{Fore.GREEN}Session ID: {self.session_id}")
        print(f"Start Time: {self.operation_start.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Operator: Leonardo Pereira Pinheiro{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}\n")
    
    def log(self, level: str, message: str, module: str = "CORE", **kwargs):
        """Log com estilo hacker"""
        icons = {
            'info': "ℹ️",
            'warning': "⚠️",
            'error': "❌",
            'success': "✅",
            'hack': "⚡",
            'stealth': "👻",
            'data': "💾"
        }
        
        icon = icons.get(level, icons['info'])
        colors = {
            'info': Fore.GREEN,
            'warning': Fore.YELLOW,
            'error': Fore.RED,
            'success': Fore.GREEN,
            'hack': Fore.MAGENTA,
            'stealth': Fore.CYAN,
            'data': Fore.BLUE
        }
        
        color = colors.get(level, Fore.WHITE)
        log_message = f"{icon} [{module}] {message}"
        
        if kwargs:
            log_message += f" | {kwargs}"
        
        if level == 'info':
            self.logger.info(f"{color}{log_message}{Style.RESET_ALL}")
        elif level == 'warning':
            self.logger.warning(f"{color}{log_message}{Style.RESET_ALL}")
        elif level == 'error':
            self.logger.error(f"{color}{log_message}{Style.RESET_ALL}")
        elif level == 'success':
            self.logger.info(f"{Fore.GREEN}{log_message}{Style.RESET_ALL}")
        else:
            self.logger.info(f"{color}{log_message}{Style.RESET_ALL}")

# =============================================================================
# MÓDULO DE RECONHECIMENTO AVANÇADO (SIMPLIFICADO)
# =============================================================================

class GhostRecon:
    """Módulo de reconhecimento estilo hacker"""
    
    def __init__(self, logger: CyberGhostLogger):
        self.logger = logger
        self.session = None
        
        # Wordlists
        self.subdomain_wordlists = {
            "basic": ["www", "mail", "ftp", "ssh", "admin", "api", "dev", "test"],
            "advanced": ["backend", "frontend", "database", "redis", "elastic"],
            "cloud": ["aws", "azure", "gcp", "cloud", "storage", "cdn"]
        }
        
        self.common_ports = {
            "web": [80, 443, 8080, 8443],
            "database": [3306, 5432, 27017, 6379],
            "remote": [22, 23, 3389],
            "services": [21, 25, 110, 143]
        }
    
    async def full_reconnaissance(self, target: str) -> Dict:
        """Reconhecimento completo no estilo hacker"""
        self.logger.log("info", f"Initiating reconnaissance on {target}", "RECON")
        
        results = {
            "target": target,
            "timestamp": datetime.now().isoformat(),
            "operator": "CyberGhost",
            "recon_data": {}
        }
        
        try:
            # Executa módulos de reconhecimento
            recon_tasks = [
                self.enumerate_subdomains(target),
                self.port_scanning(target),
                self.technology_fingerprinting(target),
                self.whois_analysis(target),
                self.web_content_analysis(target)
            ]
            
            # Executa tarefas
            for task in recon_tasks:
                try:
                    if asyncio.iscoroutinefunction(task.__call__):
                        data = await task
                    else:
                        data = task
                    
                    task_name = task.__name__ if hasattr(task, '__name__') else "unknown"
                    results["recon_data"][task_name] = data
                    
                    self.logger.log("success", f"Recon module completed: {task_name}")
                except Exception as e:
                    self.logger.log("error", f"Recon module failed: {str(e)[:100]}")
            
            return results
            
        except Exception as e:
            self.logger.log("error", f"Reconnaissance failed: {e}")
            return results
    
    async def enumerate_subdomains(self, domain: str) -> Dict:
        """Enumeração de subdomínios"""
        self.logger.log("hack", f"Enumerating subdomains for {domain}", "SUBDOMAIN")
        
        found_subs = []
        all_wordlists = []
        
        # Combina wordlists
        for wordlist in self.subdomain_wordlists.values():
            all_wordlists.extend(wordlist)
        
        # Técnica simples de DNS lookup
        for sub in all_wordlists[:50]:  # Limita para teste
            try:
                full_domain = f"{sub}.{domain}"
                resolver = dns.resolver.Resolver()
                resolver.timeout = 2
                resolver.lifetime = 2
                answers = resolver.resolve(full_domain, 'A')
                if answers:
                    found_subs.append(full_domain)
            except:
                continue
        
        return {
            "total_found": len(found_subs),
            "subdomains": found_subs,
            "techniques": ["dns_lookup"]
        }
    
    async def port_scanning(self, target: str) -> Dict:
        """Port scanning básico"""
        self.logger.log("hack", f"Port scanning {target}", "PORTSCAN")
        
        open_ports = {}
        
        try:
            import socket
            
            for service_type, ports in self.common_ports.items():
                for port in ports:
                    try:
                        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        sock.settimeout(1)
                        result = sock.connect_ex((target, port))
                        sock.close()
                        
                        if result == 0:
                            # Tenta identificar serviço
                            service_name = socket.getservbyport(port) if port < 1024 else "unknown"
                            open_ports[port] = {
                                "service": service_name,
                                "state": "open"
                            }
                    except:
                        continue
            
            return {
                "open_ports": open_ports,
                "total_open": len(open_ports)
            }
            
        except Exception as e:
            self.logger.log("error", f"Port scan failed: {e}")
            return {"error": str(e)}
    
    async def technology_fingerprinting(self, target: str) -> Dict:
        """Fingerprinting de tecnologias"""
        self.logger.log("info", f"Fingerprinting technologies for {target}", "TECH")
        
        technologies = {}
        
        try:
            # Usa builtwith
            for protocol in ["https", "http"]:
                try:
                    url = f"{protocol}://{target}"
                    tech_data = builtwith.parse(url)
                    
                    if tech_data:
                        for category, items in tech_data.items():
                            if items:
                                technologies[category] = items
                        break
                except:
                    continue
            
            return technologies if technologies else {"message": "No technologies detected"}
            
        except Exception as e:
            self.logger.log("error", f"Technology fingerprinting failed: {e}")
            return {"error": str(e)}
    
    async def whois_analysis(self, domain: str) -> Dict:
        """Análise WHOIS"""
        self.logger.log("info", f"WHOIS analysis for {domain}", "WHOIS")
        
        try:
            import whois
            
            w = whois.whois(domain)
            
            analysis = {
                "registrar": w.registrar,
                "creation_date": str(w.creation_date),
                "expiration_date": str(w.expiration_date),
                "name_servers": w.name_servers,
                "status": w.status,
            }
            
            # Calcula idade do domínio
            if w.creation_date:
                if isinstance(w.creation_date, list):
                    creation_date = w.creation_date[0]
                else:
                    creation_date = w.creation_date
                
                if creation_date:
                    age_days = (datetime.now() - creation_date).days
                    analysis["age_days"] = age_days
            
            return analysis
            
        except Exception as e:
            self.logger.log("error", f"WHOIS analysis failed: {e}")
            return {"error": str(e)}
    
    async def web_content_analysis(self, target: str) -> Dict:
        """Análise de conteúdo web"""
        self.logger.log("info", f"Analyzing web content for {target}", "WEB")
        
        content_data = {}
        
        for protocol in ["https", "http"]:
            try:
                url = f"{protocol}://{target}"
                async with aiohttp.ClientSession() as session:
                    async with session.get(url, timeout=10, ssl=False) as response:
                        
                        # Headers
                        headers = dict(response.headers)
                        
                        # Conteúdo
                        html_content = await response.text()
                        soup = BeautifulSoup(html_content, 'html.parser')
                        
                        # Extrai links
                        links = []
                        for link in soup.find_all('a', href=True):
                            links.append(link['href'])
                        
                        # Extrai scripts
                        scripts = []
                        for script in soup.find_all('script', src=True):
                            scripts.append(script['src'])
                        
                        content_data = {
                            "protocol": protocol,
                            "status": response.status,
                            "title": soup.title.string if soup.title else None,
                            "links_count": len(links),
                            "scripts_count": len(scripts),
                            "has_forms": len(soup.find_all('form')) > 0,
                            "word_count": len(html_content.split()),
                            "content_type": headers.get('Content-Type', 'unknown')
                        }
                        
                        break
            except Exception as e:
                continue
        
        return content_data if content_data else {"error": "Could not access web content"}

# =============================================================================
# MÓDULO DE INTELIGÊNCIA ARTIFICIAL (SIMPLIFICADO)
# =============================================================================

class GhostAI:
    """IA especializada em segurança cibernética"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = CyberGhostLogger("GhostAI")
    
    async def analyze_threat_pattern(self, data: Dict) -> Dict:
        """Analisa padrões de ameaça"""
        analysis = {
            "risk_prediction": await self._predict_risk(data),
            "recommendations": await self._generate_recommendations(data)
        }
        
        return analysis
    
    async def _predict_risk(self, data: Dict) -> Dict:
        """Prediz risco"""
        recon = data.get("recon_data", {})
        
        # Calcula score simples
        risk_score = 0
        
        # Subdomínios
        subs = recon.get("enumerate_subdomains", {})
        sub_count = subs.get("total_found", 0)
        if sub_count > 20:
            risk_score += 3
        elif sub_count > 10:
            risk_score += 2
        elif sub_count > 5:
            risk_score += 1
        
        # Portas abertas
        ports = recon.get("port_scanning", {})
        port_count = ports.get("total_open", 0)
        if port_count > 15:
            risk_score += 3
        elif port_count > 10:
            risk_score += 2
        elif port_count > 5:
            risk_score += 1
        
        # Determina nível
        if risk_score >= 5:
            level = "HIGH"
        elif risk_score >= 3:
            level = "MEDIUM"
        else:
            level = "LOW"
        
        return {
            "score": risk_score,
            "level": level,
            "confidence": 0.7
        }
    
    async def _generate_recommendations(self, data: Dict) -> List[Dict]:
        """Gera recomendações"""
        recommendations = []
        
        recon = data.get("recon_data", {})
        
        # Recomendações baseadas em dados
        subs = recon.get("enumerate_subdomains", {})
        if subs.get("total_found", 0) > 20:
            recommendations.append({
                "source": "System",
                "priority": "MEDIUM",
                "recommendation": "Review and clean up unused subdomains"
            })
        
        ports = recon.get("port_scanning", {})
        if ports.get("total_open", 0) > 15:
            recommendations.append({
                "source": "System",
                "priority": "HIGH",
                "recommendation": "Close unnecessary open ports"
            })
        
        # Recomendação padrão
        if not recommendations:
            recommendations.append({
                "source": "System",
                "priority": "INFO",
                "recommendation": "Regular security audits recommended"
            })
        
        return recommendations

# =============================================================================
# SISTEMA DE RELATÓRIOS (SIMPLIFICADO)
# =============================================================================

class GhostReporter:
    """Sistema de relatórios hacker"""
    
    def __init__(self):
        pass
    
    async def generate_report(self, data: Dict, format: str = "txt") -> Dict[str, Path]:
        """Gera relatório"""
        reports = {}
        
        if "txt" in format:
            reports["txt"] = self._generate_text_report(data)
        
        if "json" in format:
            reports["json"] = self._generate_json_report(data)
        
        return reports
    
    def _generate_text_report(self, data: Dict) -> Path:
        """Gera relatório em texto"""
        target = data.get("target", "Unknown")
        filename = f"cyberghost_{target}_{datetime.now():%Y%m%d_%H%M%S}.txt"
        filepath = Path("reports") / filename
        filepath.parent.mkdir(exist_ok=True)
        
        content = f"""
╔══════════════════════════════════════════════════════════════════════╗
║                        CYBERGHOST OSINT REPORT                       ║
║                     Target: {target:<40} ║
║                     Date: {datetime.now():%Y-%m-%d %H:%M:%S}                    ║
║                     Operator: Leonardo Pereira Pinheiro              ║
╚══════════════════════════════════════════════════════════════════════╝

SUMMARY:
--------
Target: {target}
Scan Time: {datetime.now():%Y-%m-%d %H:%M:%S}

FINDINGS:
---------
"""
        
        recon = data.get("recon_data", {})
        
        # Subdomains
        subs = recon.get("enumerate_subdomains", {})
        if subs:
            content += f"\nSubdomains Found: {subs.get('total_found', 0)}"
            for sub in subs.get("subdomains", [])[:10]:  # Limita para relatório
                content += f"\n  • {sub}"
        
        # Ports
        ports = recon.get("port_scanning", {})
        if ports:
            content += f"\n\nOpen Ports: {ports.get('total_open', 0)}"
            for port, info in ports.get("open_ports", {}).items():
                content += f"\n  • Port {port}: {info.get('service', 'unknown')}"
        
        # Technologies
        tech = recon.get("technology_fingerprinting", {})
        if tech:
            content += f"\n\nTechnologies Detected:"
            for category, items in tech.items():
                if items:
                    content += f"\n  • {category}: {', '.join(items[:3])}"
        
        # WHOIS
        whois_data = recon.get("whois_analysis", {})
        if whois_data and "error" not in whois_data:
            content += f"\n\nWHOIS Information:"
            content += f"\n  • Registrar: {whois_data.get('registrar', 'N/A')}"
            content += f"\n  • Created: {whois_data.get('creation_date', 'N/A')}"
            content += f"\n  • Age: {whois_data.get('age_days', 'N/A')} days"
        
        # Recommendations
        intel = data.get("intelligence", {})
        recs = intel.get("recommendations", [])
        if recs:
            content += f"\n\nRECOMMENDATIONS:"
            for rec in recs:
                content += f"\n  • [{rec.get('priority', 'INFO')}] {rec.get('recommendation', '')}"
        
        content += f"\n\n{'-'*60}"
        content += f"\nReport generated by CYBERGHOST OSINT v5.0"
        content += f"\nFor ethical and legal use only"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return filepath
    
    def _generate_json_report(self, data: Dict) -> Path:
        """Gera relatório JSON"""
        filename = f"cyberghost_{data.get('target', 'unknown')}_{datetime.now():%Y%m%d_%H%M%S}.json"
        filepath = Path("reports") / filename
        filepath.parent.mkdir(exist_ok=True)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, default=str, ensure_ascii=False)
        
        return filepath

# =============================================================================
# APLICAÇÃO PRINCIPAL CYBERGHOST
# =============================================================================

class CyberGhostOSINT:
    """Aplicação principal do CyberGhost OSINT"""
    
    def __init__(self, config_path: Optional[str] = None):
        # Carrega configuração
        self.config = CYBERGHOST_CONFIG.copy()
        
        # Inicializa componentes
        self.logger = CyberGhostLogger("CyberGhost")
        self.recon = GhostRecon(self.logger)
        self.ai = GhostAI(self.config)
        self.reporter = GhostReporter()
        
        # Status
        self.targets_scanned = 0
    
    async def ghost_scan(self, target: str, mode: str = "stealth") -> Dict:
        """Executa scan no modo CyberGhost"""
        self.targets_scanned += 1
        
        self.logger.log("stealth", f"Beginning ghost scan of {target}")
        
        try:
            # Reconhecimento
            recon_data = await self.recon.full_reconnaissance(target)
            
            # Análise de IA
            intel_data = await self.ai.analyze_threat_pattern(recon_data)
            
            # Combina dados
            full_data = {
                **recon_data,
                "intelligence": intel_data,
                "metadata": {
                    "scan_id": str(uuid.uuid4()),
                    "timestamp": datetime.now().isoformat(),
                    "operator": "Leonardo Pereira Pinheiro (CyberGhost)",
                    "mode": mode,
                    "version": self.config["version"]
                }
            }
            
            # Gera relatórios
            reports = await self.reporter.generate_report(full_data)
            
            # Log de conclusão
            threat_level = intel_data.get("risk_prediction", {}).get("level", "UNKNOWN")
            self.logger.log("success", f"Ghost scan completed for {target} - Threat: {threat_level}")
            
            # Imprime resumo
            self._print_scan_summary(full_data, reports)
            
            return {
                "data": full_data,
                "reports": reports,
                "success": True
            }
            
        except Exception as e:
            self.logger.log("error", f"Ghost scan failed: {e}")
            return {
                "error": str(e),
                "success": False
            }
    
    def _print_scan_summary(self, data: Dict, reports: Dict[str, Path]):
        """Imprime resumo do scan"""
        target = data.get("target", "Unknown")
        threat = data.get("intelligence", {}).get("risk_prediction", {})
        
        print(f"\n{Fore.CYAN}{'═'*60}")
        print(f"{Fore.GREEN} CYBERGHOST SCAN SUMMARY - {target}")
        print(f"{Fore.CYAN}{'═'*60}{Style.RESET_ALL}")
        
        # Métricas
        recon = data.get("recon_data", {})
        metrics = [
            ["Target", target],
            ["Threat Level", f"{threat.get('level', 'N/A')}"],
            ["Subdomains", recon.get("enumerate_subdomains", {}).get("total_found", 0)],
            ["Open Ports", recon.get("port_scanning", {}).get("total_open", 0)],
            ["Confidence", f"{threat.get('confidence', 0)*100:.1f}%"]
        ]
        
        print(tabulate(metrics, tablefmt="simple"))
        
        # Relatórios
        print(f"\n{Fore.CYAN}Reports Generated:{Style.RESET_ALL}")
        for fmt, path in reports.items():
            print(f"  {Fore.GREEN}•{Style.RESET_ALL} {fmt.upper()}: {path}")
        
        print(f"\n{Fore.CYAN}{'═'*60}{Style.RESET_ALL}")
    
    async def ghost_batch(self, targets_file: str, concurrent: int = 3):
        """Scans em batch"""
        with open(targets_file, 'r') as f:
            targets = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        
        self.logger.log("info", f"Starting batch scan of {len(targets)} targets")
        
        results = {}
        
        # Barra de progresso
        for target in tqdm(targets, desc="CyberGhost Batch"):
            result = await self.ghost_scan(target)
            results[target] = result
        
        # Relatório consolidado
        await self._generate_batch_report(results)
        
        return results
    
    async def _generate_batch_report(self, results: Dict):
        """Gera relatório de batch"""
        successful = sum(1 for r in results.values() if r.get("success"))
        total = len(results)
        
        report = {
            "summary": {
                "total_targets": total,
                "successful_scans": successful,
                "failed_scans": total - successful,
                "completion_time": datetime.now().isoformat()
            },
            "results": {k: v.get("data", {}) for k, v in results.items()}
        }
        
        filename = f"cyberghost_batch_{datetime.now():%Y%m%d_%H%M%S}.json"
        filepath = Path("reports") / filename
        filepath.parent.mkdir(exist_ok=True)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, default=str)
        
        self.logger.log("success", f"Batch report saved: {filepath}")

# =============================================================================
# INTERFACE DE COMANDOS
# =============================================================================

async def main():
    """Função principal"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="CYBERGHOST OSINT v5.0 - Advanced Cyber Intelligence Platform",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
---------
Single Target Scan:
  python cyberghost.py scan example.com
  
Batch Scan:
  python cyberghost.py batch targets.txt

Developer: Leonardo Pereira Pinheiro | Alias: CyberGhost
Warning: Use only for ethical and legal purposes!
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='CyberGhost Commands')
    
    # Scan command
    scan_parser = subparsers.add_parser('scan', help='Scan single target')
    scan_parser.add_argument('target', help='Target domain or IP')
    
    # Batch command
    batch_parser = subparsers.add_parser('batch', help='Batch scan')
    batch_parser.add_argument('file', help='File with targets (one per line)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    # Inicializa CyberGhost
    ghost = CyberGhostOSINT()
    
    try:
        if args.command == 'scan':
            await ghost.ghost_scan(args.target)
            
        elif args.command == 'batch':
            await ghost.ghost_batch(args.file)
            
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}[!] Operation terminated by user{Style.RESET_ALL}")
    except Exception as e:
        print(f"\n{Fore.RED}[!] CyberGhost Error: {e}{Style.RESET_ALL}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
