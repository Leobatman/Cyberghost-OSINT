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
import yaml
import tomli
import logging
import hashlib
import pickle
import base64
import uuid
import secrets
import random
import string
from datetime import datetime, timedelta, timezone
from typing import (
    Dict, List, Any, Optional, Union, Tuple, Set, Callable,
    AsyncGenerator, TypeVar, Generic, TypedDict, Literal
)
from dataclasses import dataclass, field, asdict
from enum import Enum, auto
from pathlib import Path
from functools import wraps, lru_cache
from contextlib import asynccontextmanager, contextmanager
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import inspect
import textwrap
import itertools
import statistics
import math
import decimal
import fractions
import csv
import sqlite3
import warnings
warnings.filterwarnings('ignore')

# =============================================================================
# DEPENDÊNCIAS CORE - CYBERGHOST EDITION
# =============================================================================
try:
    # Análise de Rede e Segurança
    import dns.resolver
    import dns.asyncresolver
    import dns.reversename
    import whois
    import whois.parser
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
    from bs4 import BeautifulSoup, SoupStrainer
    import builtwith
    import socket
    import ssl
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.backends import default_backend
    
    # Ferramentas de Hacking Ético
    import nmap
    import scapy.all as scapy
    from scapy.all import ARP, Ether, srp
    import paramiko
    import ftplib
    import smtplib
    from email.mime.text import MIMEText
    import telnetlib
    
    # IA e Processamento Avançado
    import torch
    import torch.nn as nn
    import transformers
    from transformers import (
        AutoTokenizer, AutoModel, pipeline,
        TextClassificationPipeline, AutoModelForSequenceClassification
    )
    import spacy
    from spacy import displacy
    import nltk
    from nltk.tokenize import word_tokenize, sent_tokenize
    from nltk.corpus import stopwords
    from nltk.stem import PorterStemmer, WordNetLemmatizer
    from textblob import TextBlob
    from langdetect import detect, detect_langs
    
    # Visualização Hacker-Style
    from colorama import Fore, Style, Back, init as colorama_init
    from tabulate import tabulate
    from tqdm.auto import tqdm
    from tqdm.asyncio import tqdm as async_tqdm
    import matplotlib.pyplot as plt
    import seaborn as sns
    import plotly.graph_objects as go
    import plotly.express as px
    import networkx as nx
    from wordcloud import WordCloud
    
    # Análise de Dados Avançada
    import pandas as pd
    import numpy as np
    from scipy import stats
    import scipy.spatial.distance as distance
    
    # Cache e Performance
    import redis
    from redis.asyncio import Redis as AsyncRedis
    import aioredis
    import diskcache
    from functools import cache, cached_property
    
    # Segurança Avançada
    import bcrypt
    import cryptography
    from cryptography.fernet import Fernet
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    
    # APIs de Inteligência Cibernética
    try:
        import openai
        from openai import AsyncOpenAI
        OPENAI_AVAILABLE = True
    except ImportError:
        OPENAI_AVAILABLE = False
        
    try:
        import shodan
        SHODAN_AVAILABLE = True
    except ImportError:
        SHODAN_AVAILABLE = False
        
    try:
        import censys
        CENSYS_AVAILABLE = True
    except ImportError:
        CENSYS_AVAILABLE = False
        
    try:
        from virus_total_apis import PublicApi as VTAPI
        VIRUSTOTAL_AVAILABLE = True
    except ImportError:
        VIRUSTOTAL_AVAILABLE = False
        
except ImportError as e:
    print(f"⚠️  Dependência necessária não encontrada: {e}")
    print("🔧 Instale com: pip install -r requirements-cyberghost.txt")
    sys.exit(1)

# =============================================================================
# CONSTANTES E CONFIGURAÇÃO - CYBERGHOST THEME
# =============================================================================

class CyberGhostMode(Enum):
    """Modos de operação do CyberGhost"""
    STEALTH = "stealth"          # Modo furtivo
    RECON = "reconnaissance"     # Reconhecimento
    ASSAULT = "assault"          # Análise agressiva
    DEFENSE = "defense"          # Modo defensivo
    FORENSIC = "forensic"        # Análise forense
    ACADEMIC = "academic"        # Pesquisa acadêmica

class ThreatLevel(Enum):
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

class HackerRank(Enum):
    """Rankings de hacker"""
    SCRIPT_KIDDIE = "Script Kiddie"
    APPRENTICE = "Apprentice"
    OPERATOR = "Operator"
    ELITE = "Elite"
    GHOST = "Ghost"
    LEGEND = "Legend"

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
        "proxy_rotation": True,
        "tor_integration": False
    },
    
    "modules": {
        "recon": {
            "subdomain_bruteforce": True,
            "port_scanning": True,
            "service_detection": True,
            "os_detection": True,
            "vulnerability_scan": False
        },
        "intel": {
            "social_media": True,
            "dark_web": False,
            "leaked_databases": False,
            "threat_intelligence": True
        },
        "analysis": {
            "ai_enhanced": True,
            "behavior_analysis": True,
            "pattern_recognition": True,
            "predictive_threat": True
        },
        "reporting": {
            "generate_report": True,
            "export_formats": ["html", "pdf", "json", "txt", "md"],
            "encrypt_reports": False,
            "upload_to_cloud": False
        }
    },
    
    "security": {
        "anonymization": True,
        "encryption": True,
        "log_cleaning": True,
        "evidence_preservation": True,
        "legal_compliance": True
    },
    
    "apis": {
        "shodan": {"enabled": True, "key": "${SHODAN_API_KEY}"},
        "censys": {"enabled": True, "key": "${CENSYS_API_KEY}"},
        "virustotal": {"enabled": True, "key": "${VIRUSTOTAL_API_KEY}"},
        "hunter": {"enabled": True, "key": "${HUNTER_API_KEY}"},
        "dehashed": {"enabled": False, "key": "${DEHASHED_API_KEY}"}
    }
}

# =============================================================================
# SISTEMA DE LOGGING HACKER-STYLE
# =============================================================================

class CyberGhostLogger:
    """Logger estilo hacker com cores e efeitos"""
    
    LOG_COLORS = {
        'DEBUG': Fore.CYAN,
        'INFO': Fore.GREEN,
        'WARNING': Fore.YELLOW,
        'ERROR': Fore.RED,
        'CRITICAL': Fore.MAGENTA + Style.BRIGHT
    }
    
    HACKER_ART = {
        'start': [
            "╔══════════════════════════════════════════════════════════╗",
            "║  ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗        ║",
            "║ ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║  ██║        ║",
            "║ ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████║        ║",
            "║ ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║        ║",
            "║ ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║  ██║        ║",
            "║  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝        ║",
            "║                CYBERGHOST OSINT v5.0                     ║",
            "║        By: Leonardo Pereira Pinheiro (CyberGhost)        ║",
            "╚══════════════════════════════════════════════════════════╝"
        ],
        'success': "✅ [SUCCESS]",
        'failure': "❌ [FAILURE]",
        'warning': "⚠️  [WARNING]",
        'info': "ℹ️  [INFO]",
        'hack': "⚡ [HACK]",
        'stealth': "👻 [STEALTH]",
        'data': "💾 [DATA]"
    }
    
    def __init__(self, name: str = "CyberGhost"):
        colorama_init(autoreset=True, strip=False)
        self.name = name
        self.session_id = str(uuid.uuid4())[:8]
        self.operation_start = datetime.now()
        
        # Setup logging tradicional
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        
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
        for line in self.HACKER_ART['start']:
            print(f"{Fore.CYAN}{line}{Style.RESET_ALL}")
        
        print(f"\n{Fore.GREEN}Session ID: {self.session_id}")
        print(f"Start Time: {self.operation_start.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Operator: Leonardo Pereira Pinheiro{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}\n")
    
    def log(self, level: str, message: str, module: str = "CORE", **kwargs):
        """Log com estilo hacker"""
        icons = {
            'info': self.HACKER_ART['info'],
            'warning': self.HACKER_ART['warning'],
            'error': self.HACKER_ART['failure'],
            'success': self.HACKER_ART['success'],
            'hack': self.HACKER_ART['hack'],
            'stealth': self.HACKER_ART['stealth'],
            'data': self.HACKER_ART['data']
        }
        
        icon = icons.get(level, icons['info'])
        color = self.LOG_COLORS.get(level.upper(), Fore.WHITE)
        
        log_message = f"{icon} [{module}] {message}"
        
        if kwargs:
            log_message += f" | {kwargs}"
        
        if level == 'info':
            self.logger.info(log_message)
        elif level == 'warning':
            self.logger.warning(log_message)
        elif level == 'error':
            self.logger.error(log_message)
        elif level == 'success':
            self.logger.info(f"{Fore.GREEN}{log_message}{Style.RESET_ALL}")
        elif level == 'hack':
            self.logger.info(f"{Fore.MAGENTA}{log_message}{Style.RESET_ALL}")
        elif level == 'stealth':
            self.logger.info(f"{Fore.CYAN}{log_message}{Style.RESET_ALL}")
        else:
            self.logger.debug(log_message)
    
    def print_status(self, target: str, status: str, details: str = ""):
        """Imprime status da operação"""
        status_colors = {
            'SCANNING': Fore.BLUE,
            'ANALYZING': Fore.CYAN,
            'COMPROMISED': Fore.RED,
            'SECURE': Fore.GREEN,
            'VULNERABLE': Fore.YELLOW,
            'COMPLETE': Fore.MAGENTA
        }
        
        color = status_colors.get(status, Fore.WHITE)
        print(f"\n{Fore.CYAN}[{datetime.now().strftime('%H:%M:%S')}] "
              f"{color}▓{Style.RESET_ALL} {status} -> {Fore.YELLOW}{target}{Style.RESET_ALL}")
        
        if details:
            print(f"   └─ {details}")
    
    def print_matrix_effect(self, text: str, speed: float = 0.05):
        """Efeito Matrix style"""
        import time
        matrix_chars = "01"
        
        print(f"\n{Fore.GREEN}", end="")
        for char in text:
            for _ in range(3):
                print(random.choice(matrix_chars), end="", flush=True)
                time.sleep(speed/3)
                print("\b", end="", flush=True)
            print(char, end="", flush=True)
            time.sleep(speed)
        print(Style.RESET_ALL)

# =============================================================================
# SISTEMA DE CACHE AVANÇADO COM ENCRYPT
# =============================================================================

class GhostCache:
    """Sistema de cache com encriptação e auto-destruição"""
    
    def __init__(self, encryption_key: str = None):
        self.memory_cache = {}
        self.disk_cache_dir = Path("./.ghost_cache")
        self.disk_cache_dir.mkdir(exist_ok=True)
        
        # Encriptação
        if encryption_key:
            self.cipher = self._init_cipher(encryption_key)
            self.encryption_enabled = True
        else:
            self.encryption_enabled = False
        
        # Auto-destruição após 24h
        self._clean_old_cache()
        
        # Contador de hits/misses
        self.stats = {"hits": 0, "misses": 0, "sets": 0}
    
    def _init_cipher(self, key: str):
        """Inicializa cifra de encriptação"""
        from cryptography.fernet import Fernet
        key_hash = hashlib.sha256(key.encode()).digest()
        fernet_key = base64.urlsafe_b64encode(key_hash[:32])
        return Fernet(fernet_key)
    
    def _encrypt(self, data: Any) -> bytes:
        """Encripta dados"""
        if not self.encryption_enabled:
            return pickle.dumps(data)
        
        serialized = pickle.dumps(data)
        return self.cipher.encrypt(serialized)
    
    def _decrypt(self, encrypted: bytes) -> Any:
        """Decripta dados"""
        if not self.encryption_enabled:
            return pickle.loads(encrypted)
        
        decrypted = self.cipher.decrypt(encrypted)
        return pickle.loads(decrypted)
    
    async def get(self, key: str, default: Any = None) -> Any:
        """Obtém valor do cache"""
        cache_key = hashlib.sha256(key.encode()).hexdigest()
        
        # Memória
        if cache_key in self.memory_cache:
            value, expiry = self.memory_cache[cache_key]
            if datetime.now() < expiry:
                self.stats["hits"] += 1
                return value
            else:
                del self.memory_cache[cache_key]
        
        # Disco
        cache_file = self.disk_cache_dir / f"{cache_key}.ghost"
        if cache_file.exists():
            try:
                encrypted = cache_file.read_bytes()
                value = self._decrypt(encrypted)
                
                # Atualiza cache de memória
                self.memory_cache[cache_key] = (value, datetime.now() + timedelta(hours=1))
                self.stats["hits"] += 1
                return value
            except:
                cache_file.unlink()
        
        self.stats["misses"] += 1
        return default
    
    async def set(self, key: str, value: Any, ttl: int = 3600):
        """Define valor no cache"""
        cache_key = hashlib.sha256(key.encode()).hexdigest()
        expiry = datetime.now() + timedelta(seconds=ttl)
        
        # Memória
        self.memory_cache[cache_key] = (value, expiry)
        
        # Disco
        encrypted = self._encrypt(value)
        cache_file = self.disk_cache_dir / f"{cache_key}.ghost"
        cache_file.write_bytes(encrypted)
        
        self.stats["sets"] += 1
    
    def burn(self):
        """Destrói todo o cache (operação limpeza)"""
        self.memory_cache.clear()
        for file in self.disk_cache_dir.glob("*.ghost"):
            file.unlink()
        
        self.logger.log("info", "Cache destroyed - Ghost Protocol Activated")
    
    def _clean_old_cache(self, max_age_hours: int = 24):
        """Limpa cache antigo"""
        cutoff = datetime.now() - timedelta(hours=max_age_hours)
        
        for file in self.disk_cache_dir.glob("*.ghost"):
            if file.stat().st_mtime < cutoff.timestamp():
                file.unlink()

# =============================================================================
# MÓDULO DE RECONHECIMENTO AVANÇADO
# =============================================================================

class GhostRecon:
    """Módulo de reconhecimento estilo hacker"""
    
    def __init__(self, logger: CyberGhostLogger, cache: GhostCache):
        self.logger = logger
        self.cache = cache
        self.session = None
        
        # Wordlists personalizadas
        self.subdomain_wordlists = self._load_ghost_wordlists()
        self.common_ports = self._load_port_lists()
        
        # Ferramentas
        self.nmap_scanner = nmap.PortScanner() if 'nmap' in sys.modules else None
    
    def _load_ghost_wordlists(self) -> Dict[str, List[str]]:
        """Carrega wordlists do CyberGhost"""
        return {
            "ghost_basic": ["www", "mail", "ftp", "ssh", "admin", "api", "dev", "test", "staging", "prod"],
            "ghost_advanced": ["backend", "frontend", "database", "redis", "elastic", "kibana", "grafana", "jenkins"],
            "ghost_cloud": ["aws", "azure", "gcp", "cloud", "storage", "bucket", "cdn", "s3"],
            "ghost_security": ["vpn", "secure", "auth", "login", "oauth", "sso", "admin", "root"],
            "ghost_internal": ["internal", "intranet", "local", "devops", "monitoring", "log", "backup"]
        }
    
    def _load_port_lists(self) -> Dict[str, List[int]]:
        """Listas de portas para scanning"""
        return {
            "web": [80, 443, 8080, 8443, 3000, 8000, 8888],
            "database": [3306, 5432, 27017, 6379, 9200, 9300],
            "remote": [22, 23, 3389, 5900, 5985, 5986],
            "services": [21, 25, 110, 143, 465, 587, 993, 995],
            "special": [1337, 31337, 666, 9999, 12345, 54321]
        }
    
    async def full_reconnaissance(self, target: str) -> Dict:
        """Reconhecimento completo no estilo hacker"""
        self.logger.print_status(target, "SCANNING", "Initiating full reconnaissance")
        
        results = {
            "target": target,
            "timestamp": datetime.now().isoformat(),
            "operator": "CyberGhost",
            "recon_data": {}
        }
        
        # Executa módulos de reconhecimento
        recon_tasks = [
            self.enumerate_subdomains(target),
            self.port_scanning(target),
            self.service_detection(target),
            self.technology_fingerprinting(target),
            self.whois_analysis(target),
            self.dns_intelligence(target),
            self.web_content_analysis(target)
        ]
        
        # Executa em paralelo
        tasks = [asyncio.create_task(task) for task in recon_tasks]
        
        for i, task in enumerate(asyncio.as_completed(tasks)):
            try:
                module_name = recon_tasks[i].__name__ if i < len(recon_tasks) else f"module_{i}"
                data = await task
                results["recon_data"][module_name] = data
                
                self.logger.log("success", f"Recon module completed: {module_name}")
            except Exception as e:
                self.logger.log("error", f"Recon module failed: {str(e)[:100]}")
        
        # Análise de inteligência
        results["intelligence"] = await self.generate_intelligence_report(results["recon_data"])
        
        return results
    
    async def enumerate_subdomains(self, domain: str) -> Dict:
        """Enumeração agressiva de subdomínios"""
        self.logger.log("hack", f"Enumerating subdomains for {domain}")
        
        found_subs = []
        all_wordlists = []
        
        # Combina todas as wordlists
        for wordlist in self.subdomain_wordlists.values():
            all_wordlists.extend(wordlist)
        
        # Técnicas de enumeração
        techniques = {
            "bruteforce": await self._bruteforce_subdomains(domain, all_wordlists),
            "dns_enum": await self._dns_enumeration(domain),
            "cert_transparency": await self._certificate_transparency(domain),
            "search_engines": await self._search_engine_dorking(domain)
        }
        
        # Consolida resultados
        for tech, subs in techniques.items():
            if subs:
                found_subs.extend(subs)
        
        # Remove duplicatas
        unique_subs = list(set(found_subs))
        
        # Valida subdomínios
        validated = await self._validate_subdomains(domain, unique_subs)
        
        # Classifica por risco
        classified = self._classify_subdomains_by_risk(validated)
        
        return {
            "total_found": len(unique_subs),
            "validated": validated,
            "classified": classified,
            "techniques": {k: len(v) for k, v in techniques.items() if v}
        }
    
    async def port_scanning(self, target: str) -> Dict:
        """Port scanning avançado"""
        self.logger.log("hack", f"Port scanning {target}")
        
        if not self.nmap_scanner:
            return {"error": "NMAP not available"}
        
        open_ports = {}
        
        try:
            # Scan rápido das portas comuns
            for service_type, ports in self.common_ports.items():
                self.logger.log("info", f"Scanning {service_type} ports")
                
                port_str = ",".join(map(str, ports))
                self.nmap_scanner.scan(target, port_str, arguments='-sS -T4')
                
                for host in self.nmap_scanner.all_hosts():
                    for proto in self.nmap_scanner[host].all_protocols():
                        ports = self.nmap_scanner[host][proto].keys()
                        
                        for port in ports:
                            port_info = self.nmap_scanner[host][proto][port]
                            if port_info['state'] == 'open':
                                open_ports[port] = {
                                    "service": port_info.get('name', 'unknown'),
                                    "version": port_info.get('version', ''),
                                    "product": port_info.get('product', ''),
                                    "extra": port_info.get('extrainfo', '')
                                }
            
            # Detecção de serviços vulneráveis
            vulnerable = self._detect_vulnerable_services(open_ports)
            
            return {
                "open_ports": open_ports,
                "vulnerable_services": vulnerable,
                "total_open": len(open_ports)
            }
            
        except Exception as e:
            self.logger.log("error", f"Port scan failed: {e}")
            return {"error": str(e)}
    
    async def service_detection(self, target: str) -> Dict:
        """Detecção avançada de serviços"""
        services = {}
        
        # HTTP/HTTPS
        http_info = await self._analyze_http_service(target)
        if http_info:
            services["web"] = http_info
        
        # SSH
        ssh_info = await self._analyze_ssh_service(target)
        if ssh_info:
            services["ssh"] = ssh_info
        
        # FTP
        ftp_info = await self._analyze_ftp_service(target)
        if ftp_info:
            services["ftp"] = ftp_info
        
        # Database services
        db_info = await self._analyze_database_services(target)
        if db_info:
            services["databases"] = db_info
        
        return services
    
    async def technology_fingerprinting(self, target: str) -> Dict:
        """Fingerprinting de tecnologias"""
        self.logger.log("info", f"Fingerprinting technologies for {target}")
        
        technologies = {}
        
        try:
            # Usa builtwith
            url = f"https://{target}"
            tech_data = builtwith.parse(url)
            
            # Categoriza
            for category, items in tech_data.items():
                if items:
                    technologies[category] = items
            
            # Análise adicional
            wappalyzer_results = await self._wappalyzer_analysis(target)
            if wappalyzer_results:
                technologies["wappalyzer"] = wappalyzer_results
            
            # Detecção de frameworks
            frameworks = await self._detect_frameworks(target)
            if frameworks:
                technologies["frameworks"] = frameworks
            
            return technologies
            
        except Exception as e:
            self.logger.log("error", f"Technology fingerprinting failed: {e}")
            return {"error": str(e)}
    
    async def whois_analysis(self, domain: str) -> Dict:
        """Análise WHOIS com inteligência"""
        self.logger.log("info", f"WHOIS analysis for {domain}")
        
        try:
            w = whois.whois(domain)
            
            analysis = {
                "registrar": w.registrar,
                "creation_date": w.creation_date,
                "expiration_date": w.expiration_date,
                "name_servers": w.name_servers,
                "status": w.status,
                "emails": w.emails,
                "organization": w.org,
                "country": w.country,
                "raw": str(w)[:2000]  # Limita tamanho
            }
            
            # Análise de inteligência
            analysis["intelligence"] = {
                "age_days": self._calculate_domain_age(w.creation_date),
                "privacy_protection": self._check_privacy_protection(w),
                "reputation_score": await self._calculate_reputation_score(domain),
                "associated_domains": await self._find_associated_domains(w)
            }
            
            return analysis
            
        except Exception as e:
            self.logger.log("error", f"WHOIS analysis failed: {e}")
            return {"error": str(e)}
    
    async def dns_intelligence(self, domain: str) -> Dict:
        """Inteligência DNS avançada"""
        dns_data = {}
        
        record_types = ["A", "AAAA", "MX", "TXT", "NS", "SOA", "CNAME", "PTR", "SRV"]
        
        for rtype in record_types:
            try:
                resolver = dns.resolver.Resolver()
                answers = resolver.resolve(domain, rtype)
                
                values = [str(r) for r in answers]
                dns_data[rtype] = {
                    "values": values,
                    "count": len(values)
                }
                
                # Análise especial por tipo
                if rtype == "TXT":
                    dns_data[rtype]["analysis"] = self._analyze_txt_records(values)
                elif rtype == "MX":
                    dns_data[rtype]["analysis"] = self._analyze_mx_records(values)
                
            except Exception as e:
                continue
        
        # DNS Security
        dns_data["security"] = {
            "dnssec": await self._check_dnssec(domain),
            "vulnerabilities": await self._check_dns_vulnerabilities(domain, dns_data)
        }
        
        return dns_data
    
    async def web_content_analysis(self, target: str) -> Dict:
        """Análise de conteúdo web"""
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
                        
                        content_data = {
                            "protocol": protocol,
                            "status": response.status,
                            "headers": headers,
                            "title": soup.title.string if soup.title else None,
                            "meta_tags": self._extract_meta_tags(soup),
                            "links": self._extract_links(soup, target),
                            "forms": self._extract_forms(soup),
                            "scripts": self._extract_scripts(soup),
                            "comments": self._extract_comments(soup),
                            "emails": self._extract_emails(html_content),
                            "phones": self._extract_phone_numbers(html_content),
                            "word_count": len(html_content.split()),
                            "security_headers": self._analyze_security_headers(headers)
                        }
                        
                        break
            except:
                continue
        
        return content_data if content_data else {"error": "Could not access web content"}
    
    async def generate_intelligence_report(self, recon_data: Dict) -> Dict:
        """Gera relatório de inteligência"""
        report = {
            "threat_assessment": self._assess_threat_level(recon_data),
            "attack_surface": self._calculate_attack_surface(recon_data),
            "vulnerabilities": self._identify_vulnerabilities(recon_data),
            "recommendations": self._generate_recommendations(recon_data),
            "confidence_score": self._calculate_confidence_score(recon_data)
        }
        
        return report
    
    # ========== MÉTODOS AUXILIARES ==========
    
    async def _bruteforce_subdomains(self, domain: str, wordlist: List[str]) -> List[str]:
        """Bruteforce de subdomínios"""
        found = []
        
        async def check_subdomain(sub: str):
            full = f"{sub}.{domain}"
            try:
                resolver = dns.asyncresolver.Resolver()
                await resolver.resolve(full, 'A', lifetime=2)
                return full
            except:
                return None
        
        # Limita concorrência
        semaphore = asyncio.Semaphore(50)
        
        async def bounded_check(sub: str):
            async with semaphore:
                return await check_subdomain(sub)
        
        tasks = [bounded_check(sub) for sub in wordlist]
        results = await asyncio.gather(*tasks)
        
        return [r for r in results if r]
    
    def _detect_vulnerable_services(self, open_ports: Dict) -> List[Dict]:
        """Detecta serviços vulneráveis"""
        vulnerable = []
        
        vulnerable_patterns = {
            "ftp": {"ports": [21], "risk": "HIGH"},
            "telnet": {"ports": [23], "risk": "CRITICAL"},
            "vnc": {"ports": [5900], "risk": "HIGH"},
            "rdp": {"ports": [3389], "risk": "MEDIUM"},
            "redis": {"ports": [6379], "risk": "HIGH"},
            "mongodb": {"ports": [27017], "risk": "MEDIUM"}
        }
        
        for port, info in open_ports.items():
            service = info.get("service", "").lower()
            
            for vuln_service, pattern in vulnerable_patterns.items():
                if port in pattern["ports"] or vuln_service in service:
                    vulnerable.append({
                        "port": port,
                        "service": service,
                        "risk": pattern["risk"],
                        "details": info
                    })
        
        return vulnerable
    
    def _calculate_domain_age(self, creation_date) -> int:
        """Calcula idade do domínio em dias"""
        if not creation_date:
            return 0
        
        try:
            if isinstance(creation_date, list):
                creation = creation_date[0]
            else:
                creation = creation_date
            
            if isinstance(creation, str):
                from dateutil import parser
                creation = parser.parse(creation)
            
            age = (datetime.now() - creation).days
            return max(0, age)
        except:
            return 0
    
    def _assess_threat_level(self, recon_data: Dict) -> Dict:
        """Avalia nível de ameaça"""
        score = 0
        factors = []
        
        # Subdomínios
        subs = recon_data.get("enumerate_subdomains", {})
        if subs.get("total_found", 0) > 20:
            score += 2
            factors.append("Many subdomains")
        
        # Portas abertas
        ports = recon_data.get("port_scanning", {})
        if ports.get("total_open", 0) > 10:
            score += 2
            factors.append("Many open ports")
        
        # Serviços vulneráveis
        vuln_services = ports.get("vulnerable_services", [])
        if vuln_services:
            score += len(vuln_services) * 3
            factors.append(f"{len(vuln_services)} vulnerable services")
        
        # Determine threat level
        if score >= 10:
            level = "CRITICAL"
        elif score >= 6:
            level = "HIGH"
        elif score >= 3:
            level = "MEDIUM"
        else:
            level = "LOW"
        
        return {
            "level": level,
            "score": score,
            "factors": factors
        }

# =============================================================================
# MÓDULO DE INTELIGÊNCIA ARTIFICIAL - CYBERGHOST AI
# =============================================================================

class GhostAI:
    """IA especializada em segurança cibernética"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = CyberGhostLogger("GhostAI")
        
        # Carrega modelos
        self._load_models()
        
        # Inicializa APIs
        self._init_apis()
    
    def _load_models(self):
        """Carrega modelos de IA"""
        try:
            # Modelo para análise de segurança
            self.security_model = pipeline(
                "text-classification",
                model="mrm8488/bert-tiny-finetuned-cyberbullying"
            )
        except:
            self.security_model = None
        
        # Modelo para detecção de anomalias
        try:
            from sklearn.ensemble import IsolationForest
            self.anomaly_detector = IsolationForest(contamination=0.1)
        except:
            self.anomaly_detector = None
        
        # NLP para análise de texto
        try:
            self.nlp = spacy.load("en_core_web_lg")
        except:
            self.nlp = None
    
    def _init_apis(self):
        """Inicializa APIs de IA"""
        if OPENAI_AVAILABLE and self.config.get("openai_api_key"):
            self.openai = AsyncOpenAI(api_key=self.config["openai_api_key"])
        else:
            self.openai = None
        
        if SHODAN_AVAILABLE and self.config.get("shodan_api_key"):
            self.shodan = shodan.Shodan(self.config["shodan_api_key"])
        else:
            self.shodan = None
    
    async def analyze_threat_pattern(self, data: Dict) -> Dict:
        """Analisa padrões de ameaça com IA"""
        analysis = {
            "risk_prediction": await self._predict_risk(data),
            "anomaly_detection": self._detect_anomalies(data),
            "behavior_analysis": await self._analyze_behavior(data),
            "attack_prediction": await self._predict_attack_vectors(data),
            "recommendations": await self._generate_ai_recommendations(data)
        }
        
        return analysis
    
    async def _predict_risk(self, data: Dict) -> Dict:
        """Prediz risco com IA"""
        features = self._extract_risk_features(data)
        
        # Simulação de modelo de ML
        risk_score = min(1.0, sum(features) / len(features) if features else 0.5)
        
        if risk_score > 0.8:
            level = "CRITICAL"
        elif risk_score > 0.6:
            level = "HIGH"
        elif risk_score > 0.4:
            level = "MEDIUM"
        elif risk_score > 0.2:
            level = "LOW"
        else:
            level = "INFO"
        
        return {
            "score": round(risk_score, 3),
            "level": level,
            "confidence": 0.85
        }
    
    def _extract_risk_features(self, data: Dict) -> List[float]:
        """Extrai features para análise de risco"""
        features = []
        
        # Subdomínios
        subs = data.get("recon_data", {}).get("enumerate_subdomains", {})
        features.append(min(subs.get("total_found", 0) / 50, 1.0))
        
        # Portas abertas
        ports = data.get("recon_data", {}).get("port_scanning", {})
        features.append(min(ports.get("total_open", 0) / 20, 1.0))
        
        # Serviços vulneráveis
        vuln = ports.get("vulnerable_services", [])
        features.append(min(len(vuln) / 5, 1.0))
        
        # Tecnologias antigas
        tech = data.get("recon_data", {}).get("technology_fingerprinting", {})
        features.append(0.3 if self._has_outdated_tech(tech) else 0.0)
        
        return features
    
    def _detect_anomalies(self, data: Dict) -> List[Dict]:
        """Detecta anomalias nos dados"""
        anomalies = []
        
        # Verifica padrões suspeitos
        recon = data.get("recon_data", {})
        
        # Muitos subdomínios similares
        subs = recon.get("enumerate_subdomains", {}).get("validated", [])
        if len(subs) > 30:
            anomalies.append({
                "type": "EXCESSIVE_SUBDOMAINS",
                "severity": "MEDIUM",
                "description": f"Found {len(subs)} subdomains, possible DGA"
            })
        
        # Portas não padrão abertas
        ports = recon.get("port_scanning", {}).get("open_ports", {})
        suspicious_ports = [666, 31337, 1337, 12345]
        for port in suspicious_ports:
            if str(port) in ports:
                anomalies.append({
                    "type": "SUSPICIOUS_PORT",
                    "severity": "HIGH",
                    "description": f"Suspicious port {port} open"
                })
        
        return anomalies
    
    async def _analyze_behavior(self, data: Dict) -> Dict:
        """Analisa comportamento do alvo"""
        behavior = {
            "fingerprint": self._generate_fingerprint(data),
            "patterns": self._identify_patterns(data),
            "profile": await self._create_target_profile(data)
        }
        
        return behavior
    
    def _generate_fingerprint(self, data: Dict) -> str:
        """Gera fingerprint único do alvo"""
        fingerprint_data = {
            "subdomains": len(data.get("recon_data", {}).get("enumerate_subdomains", {}).get("validated", [])),
            "open_ports": data.get("recon_data", {}).get("port_scanning", {}).get("total_open", 0),
            "technologies": len(data.get("recon_data", {}).get("technology_fingerprinting", {}))
        }
        
        fingerprint_str = json.dumps(fingerprint_data, sort_keys=True)
        return hashlib.sha256(fingerprint_str.encode()).hexdigest()[:16]
    
    async def _predict_attack_vectors(self, data: Dict) -> List[Dict]:
        """Prediz vetores de ataque possíveis"""
        vectors = []
        
        recon = data.get("recon_data", {})
        
        # Web attacks
        web_data = recon.get("web_content_analysis", {})
        if web_data.get("status") == 200:
            vectors.append({
                "type": "WEB_APPLICATION",
                "probability": 0.7,
                "methods": ["SQLi", "XSS", "CSRF"]
            })
        
        # Service attacks
        ports = recon.get("port_scanning", {}).get("open_ports", {})
        for port, info in ports.items():
            service = info.get("service", "").lower()
            
            if service in ["ssh", "ftp", "telnet"]:
                vectors.append({
                    "type": "SERVICE_BRUTEFORCE",
                    "probability": 0.8,
                    "target": f"{port}/{service}"
                })
        
        return vectors
    
    async def _generate_ai_recommendations(self, data: Dict) -> List[Dict]:
        """Gera recomendações com IA"""
        recommendations = []
        
        # Usa OpenAI se disponível
        if self.openai:
            try:
                prompt = f"""Based on this recon data, provide 3 security recommendations:
                
                Data: {json.dumps(data, indent=2)[:2000]}
                
                Recommendations:"""
                
                response = await self.openai.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are a cybersecurity expert."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.7,
                    max_tokens=500
                )
                
                ai_recommendations = response.choices[0].message.content.split("\n")
                for rec in ai_recommendations[:3]:
                    if rec.strip():
                        recommendations.append({
                            "source": "AI",
                            "recommendation": rec.strip()
                        })
                
            except Exception as e:
                self.logger.log("error", f"AI recommendation failed: {e}")
        
        # Fallback para recomendações padrão
        if not recommendations:
            recommendations = self._generate_default_recommendations(data)
        
        return recommendations
    
    def _generate_default_recommendations(self, data: Dict) -> List[Dict]:
        """Gera recomendações padrão"""
        recommendations = []
        
        # Recomendações baseadas em dados
        recon = data.get("recon_data", {})
        
        # Subdomínios
        subs = recon.get("enumerate_subdomains", {})
        if subs.get("total_found", 0) > 20:
            recommendations.append({
                "source": "System",
                "priority": "MEDIUM",
                "recommendation": "Review and clean up unused subdomains to reduce attack surface"
            })
        
        # Portas abertas
        ports = recon.get("port_scanning", {})
        if ports.get("total_open", 0) > 15:
            recommendations.append({
                "source": "System",
                "priority": "HIGH",
                "recommendation": "Close unnecessary open ports and implement firewall rules"
            })
        
        return recommendations

# =============================================================================
# SISTEMA DE VISUALIZAÇÃO HACKER-STYLE
# =============================================================================

class GhostVisualizer:
    """Visualização de dados estilo hacker"""
    
    def __init__(self):
        plt.style.use('dark_background')
        self.cyber_colors = ['#00ff41', '#008f11', '#0c0', '#00ff9d', '#00b894']
        
        # Configura Plotly para tema hacker
        self.hacker_template = go.layout.Template(
            layout=go.Layout(
                paper_bgcolor='rgba(0,0,0,0)',
                plot_bgcolor='rgba(0,0,0,0)',
                font=dict(color='#00ff41'),
                title=dict(font=dict(color='#00ff41', size=20)),
                xaxis=dict(
                    gridcolor='rgba(0, 255, 65, 0.1)',
                    linecolor='#00ff41',
                    zerolinecolor='rgba(0, 255, 65, 0.3)'
                ),
                yaxis=dict(
                    gridcolor='rgba(0, 255, 65, 0.1)',
                    linecolor='#00ff41',
                    zerolinecolor='rgba(0, 255, 65, 0.3)'
                )
            )
        )
    
    def create_cyber_dashboard(self, analysis_data: Dict) -> Dict[str, go.Figure]:
        """Cria dashboard cyberpunk"""
        figures = {}
        
        # Network Graph Matrix Style
        figures["network_matrix"] = self._create_matrix_network(analysis_data)
        
        # Threat Radar
        figures["threat_radar"] = self._create_threat_radar(analysis_data)
        
        # Port Heatmap
        figures["port_heatmap"] = self._create_port_heatmap(analysis_data)
        
        # Timeline Hack
        figures["hack_timeline"] = self._create_hack_timeline(analysis_data)
        
        # Vulnerability Tree
        figures["vuln_tree"] = self._create_vulnerability_tree(analysis_data)
        
        # Data Stream
        figures["data_stream"] = self._create_data_stream(analysis_data)
        
        return figures
    
    def _create_matrix_network(self, data: Dict) -> go.Figure:
        """Cria gráfico de rede estilo Matrix"""
        G = nx.Graph()
        
        # Adiciona nós
        target = data.get("target", "TARGET")
        G.add_node(target, size=30, color='#00ff41')
        
        # Adiciona subdomínios
        subs = data.get("recon_data", {}).get("enumerate_subdomains", {}).get("validated", [])
        for i, sub in enumerate(subs[:15]):  # Limita para clareza
            G.add_node(sub, size=10, color=self.cyber_colors[i % len(self.cyber_colors)])
            G.add_edge(target, sub, weight=1)
        
        # Layout 3D
        pos = nx.spring_layout(G, dim=3, seed=42)
        
        # Extrai coordenadas
        node_x, node_y, node_z, node_text = [], [], [], []
        for node in G.nodes():
            x, y, z = pos[node]
            node_x.append(x)
            node_y.append(y)
            node_z.append(z)
            node_text.append(node)
        
        # Arestas
        edge_x, edge_y, edge_z = [], [], []
        for edge in G.edges():
            x0, y0, z0 = pos[edge[0]]
            x1, y1, z1 = pos[edge[1]]
            edge_x.extend([x0, x1, None])
            edge_y.extend([y0, y1, None])
            edge_z.extend([z0, z1, None])
        
        # Cria figura 3D
        edge_trace = go.Scatter3d(
            x=edge_x, y=edge_y, z=edge_z,
            mode='lines',
            line=dict(width=1, color='rgba(0, 255, 65, 0.5)'),
            hoverinfo='none'
        )
        
        node_trace = go.Scatter3d(
            x=node_x, y=node_y, z=node_z,
            mode='markers+text',
            text=node_text,
            textposition="top center",
            marker=dict(
                size=[G.nodes[node]['size'] for node in G.nodes()],
                color=[G.nodes[node]['color'] for node in G.nodes()],
                symbol='circle',
                line=dict(width=2, color='#00ff41')
            ),
            hoverinfo='text'
        )
        
        fig = go.Figure(data=[edge_trace, node_trace])
        fig.update_layout(
            title="<b>MATRIX NETWORK MAP</b>",
            scene=dict(
                xaxis=dict(showbackground=False, showticklabels=False, title=''),
                yaxis=dict(showbackground=False, showticklabels=False, title=''),
                zaxis=dict(showbackground=False, showticklabels=False, title='')
            ),
            template=self.hacker_template,
            showlegend=False,
            margin=dict(t=50, b=0, l=0, r=0)
        )
        
        return fig
    
    def _create_threat_radar(self, data: Dict) -> go.Figure:
        """Cria radar de ameaças"""
        categories = ['SUBDOMAINS', 'OPEN PORTS', 'VULNERABILITIES', 'TECH STACK', 'WEB SECURITY']
        
        # Calcula scores
        recon = data.get("recon_data", {})
        
        scores = [
            min(len(recon.get("enumerate_subdomains", {}).get("validated", [])) / 30, 1),
            min(recon.get("port_scanning", {}).get("total_open", 0) / 20, 1),
            min(len(recon.get("port_scanning", {}).get("vulnerable_services", [])) / 5, 1),
            min(len(recon.get("technology_fingerprinting", {})) / 10, 1),
            0.7  # Placeholder para web security
        ]
        
        fig = go.Figure(data=go.Scatterpolar(
            r=scores,
            theta=categories,
            fill='toself',
            fillcolor='rgba(0, 255, 65, 0.3)',
            line=dict(color='#00ff41', width=3),
            marker=dict(size=8, color='#00ff41')
        ))
        
        fig.update_layout(
            polar=dict(
                radialaxis=dict(
                    visible=True,
                    range=[0, 1],
                    gridcolor='rgba(0, 255, 65, 0.2)',
                    linecolor='#00ff41'
                ),
                angularaxis=dict(
                    gridcolor='rgba(0, 255, 65, 0.2)',
                    linecolor='#00ff41'
                ),
                bgcolor='rgba(0,0,0,0)'
            ),
            title="<b>THREAT ASSESSMENT RADAR</b>",
            template=self.hacker_template,
            showlegend=False
        )
        
        return fig
    
    def _create_port_heatmap(self, data: Dict) -> go.Figure:
        """Cria heatmap de portas"""
        ports = data.get("recon_data", {}).get("port_scanning", {}).get("open_ports", {})
        
        if not ports:
            return go.Figure()
        
        # Agrupa portas por serviço
        service_groups = {}
        for port, info in ports.items():
            service = info.get("service", "unknown")
            if service not in service_groups:
                service_groups[service] = []
            service_groups[service].append(int(port))
        
        # Prepara dados para heatmap
        services = list(service_groups.keys())
        max_port = max([p for ports in service_groups.values() for p in ports], default=10000)
        
        # Cria matriz
        matrix = []
        for service in services:
            row = [0] * (max_port // 1000 + 1)
            for port in service_groups[service]:
                bucket = port // 1000
                if bucket < len(row):
                    row[bucket] += 1
            matrix.append(row)
        
        fig = go.Figure(data=go.Heatmap(
            z=matrix,
            x=[f"{i*1000}-{(i+1)*1000-1}" for i in range(max_port // 1000 + 1)],
            y=services,
            colorscale=[[0, 'rgba(0,0,0,0)'], [1, '#00ff41']],
            showscale=False,
            hoverongaps=False
        ))
        
        fig.update_layout(
            title="<b>PORT DISTRIBUTION HEATMAP</b>",
            xaxis_title="Port Range",
            yaxis_title="Service",
            template=self.hacker_template
        )
        
        return fig

# =============================================================================
# SISTEMA DE RELATÓRIOS CYBERGHOST
# =============================================================================

class GhostReporter:
    """Sistema de relatórios hacker"""
    
    def __init__(self, visualizer: GhostVisualizer):
        self.viz = visualizer
        self.templates = self._load_ghost_templates()
    
    def _load_ghost_templates(self) -> Dict:
        """Carrega templates hacker"""
        return {
            "stealth": self._stealth_template(),
            "assault": self._assault_template(),
            "forensic": self._forensic_template(),
            "executive": self._executive_template()
        }
    
    async def generate_report(self, data: Dict, format: str = "html", 
                             style: str = "stealth") -> Dict[str, Path]:
        """Gera relatório no estilo CyberGhost"""
        reports = {}
        
        # Gera visualizações
        figures = self.viz.create_cyber_dashboard(data)
        
        # Gera diferentes formatos
        if "html" in format or format == "all":
            reports["html"] = await self._generate_html_report(data, figures, style)
        
        if "txt" in format or format == "all":
            reports["txt"] = self._generate_text_report(data)
        
        if "json" in format or format == "all":
            reports["json"] = self._generate_json_report(data)
        
        if "md" in format or format == "all":
            reports["md"] = self._generate_markdown_report(data)
        
        return reports
    
    async def _generate_html_report(self, data: Dict, figures: Dict, 
                                   style: str) -> Path:
        """Gera relatório HTML hacker"""
        template = self.templates.get(style, self.templates["stealth"])
        
        # Prepara dados
        target = data.get("target", "Unknown")
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Gera conteúdo
        content = template.format(
            title=f"CYBERGHOST REPORT - {target}",
            timestamp=timestamp,
            target=target,
            operator="Leonardo Pereira Pinheiro (CyberGhost)",
            executive_summary=self._generate_executive_summary(data),
            technical_findings=self._generate_technical_findings(data),
            threat_analysis=self._generate_threat_analysis(data),
            recommendations=self._generate_recommendations(data),
            visualizations=self._embed_visualizations(figures),
            raw_data=self._generate_raw_data_section(data)
        )
        
        # Salva arquivo
        filename = f"cyberghost_report_{target}_{datetime.now():%Y%m%d_%H%M%S}.html"
        filepath = Path("reports") / filename
        filepath.parent.mkdir(exist_ok=True)
        
        async with aiofiles.open(filepath, 'w', encoding='utf-8') as f:
            await f.write(content)
        
        return filepath
    
    def _generate_text_report(self, data: Dict) -> Path:
        """Gera relatório em texto ASCII art"""
        target = data.get("target", "Unknown")
        filename = f"cyberghost_{target}_{datetime.now():%Y%m%d_%H%M%S}.txt"
        filepath = Path("reports") / filename
        
        content = f"""
╔══════════════════════════════════════════════════════════════════════╗
║                        CYBERGHOST OSINT REPORT                       ║
║                     Target: {target:<40} ║
║                     Date: {datetime.now():%Y-%m-%d %H:%M:%S}                    ║
║                     Operator: Leonardo Pereira Pinheiro              ║
╚══════════════════════════════════════════════════════════════════════╝

{self._generate_text_summary(data)}

{self._generate_text_findings(data)}

{self._generate_text_recommendations(data)}
        """
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return filepath
    
    def _generate_json_report(self, data: Dict) -> Path:
        """Gera relatório JSON completo"""
        filename = f"cyberghost_{data.get('target', 'unknown')}_{datetime.now():%Y%m%d_%H%M%S}.json"
        filepath = Path("reports") / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, default=str, ensure_ascii=False)
        
        return filepath
    
    # ========== TEMPLATES HACKER ==========
    
    def _stealth_template(self) -> str:
        """Template stealth mode"""
        return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&display=swap');
        
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Share Tech Mono', monospace;
            background: #000;
            color: #00ff41;
            line-height: 1.6;
            padding: 20px;
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(0, 255, 65, 0.05) 0%, transparent 20%),
                radial-gradient(circle at 90% 80%, rgba(0, 255, 65, 0.05) 0%, transparent 20%);
        }}
        
        .cyber-container {{
            max-width: 1200px;
            margin: 0 auto;
            border: 1px solid #00ff41;
            box-shadow: 0 0 20px rgba(0, 255, 65, 0.3);
            padding: 30px;
            position: relative;
            overflow: hidden;
        }}
        
        .cyber-container::before {{
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, #00ff41, transparent);
        }}
        
        .cyber-header {{
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 1px solid #00ff41;
            position: relative;
        }}
        
        .cyber-title {{
            font-size: 2.5em;
            text-transform: uppercase;
            letter-spacing: 3px;
            margin-bottom: 10px;
            text-shadow: 0 0 10px #00ff41;
        }}
        
        .cyber-subtitle {{
            color: #0c0;
            font-size: 1.2em;
        }}
        
        .cyber-section {{
            margin-bottom: 40px;
            padding: 20px;
            border: 1px solid rgba(0, 255, 65, 0.3);
            background: rgba(0, 20, 0, 0.3);
            position: relative;
        }}
        
        .cyber-section h2 {{
            color: #00ff9d;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #00ff41;
            text-transform: uppercase;
            letter-spacing: 2px;
        }}
        
        .cyber-metric {{
            display: inline-block;
            margin: 10px;
            padding: 15px;
            border: 1px solid #00ff41;
            min-width: 150px;
            text-align: center;
            background: rgba(0, 255, 65, 0.1);
        }}
        
        .cyber-metric .value {{
            font-size: 2em;
            font-weight: bold;
            color: #00ff41;
        }}
        
        .cyber-metric .label {{
            font-size: 0.9em;
            color: #0c0;
            text-transform: uppercase;
        }}
        
        .cyber-table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }}
        
        .cyber-table th {{
            background: rgba(0, 255, 65, 0.2);
            color: #00ff41;
            padding: 10px;
            text-align: left;
            border: 1px solid #00ff41;
        }}
        
        .cyber-table td {{
            padding: 10px;
            border: 1px solid rgba(0, 255, 65, 0.3);
        }}
        
        .cyber-table tr:hover {{
            background: rgba(0, 255, 65, 0.1);
        }}
        
        .risk-critical {{ color: #ff0000; text-shadow: 0 0 10px #ff0000; }}
        .risk-high {{ color: #ff3300; }}
        .risk-medium {{ color: #ff9900; }}
        .risk-low {{ color: #00ff41; }}
        .risk-info {{ color: #0099ff; }}
        
        .visualization-container {{
            margin: 30px 0;
            text-align: center;
        }}
        
        .matrix-effect {{
            font-family: 'Courier New', monospace;
            white-space: pre;
            overflow: hidden;
            border: 1px solid #00ff41;
            padding: 20px;
            background: #000;
            margin: 20px 0;
        }}
        
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #00ff41;
            color: #0c0;
            font-size: 0.9em;
        }}
        
        .glitch {{
            position: relative;
            animation: glitch 5s infinite;
        }}
        
        @keyframes glitch {{
            0% {{ transform: translate(0); }}
            20% {{ transform: translate(-2px, 2px); }}
            40% {{ transform: translate(-2px, -2px); }}
            60% {{ transform: translate(2px, 2px); }}
            80% {{ transform: translate(2px, -2px); }}
            100% {{ transform: translate(0); }}
        }}
        
        @keyframes scanline {{
            0% {{ transform: translateY(-100%); }}
            100% {{ transform: translateY(100vh); }}
        }}
        
        .scanline {{
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: rgba(0, 255, 65, 0.3);
            animation: scanline 10s linear infinite;
            pointer-events: none;
            z-index: 9999;
        }}
    </style>
</head>
<body>
    <div class="scanline"></div>
    
    <div class="cyber-container">
        <div class="cyber-header">
            <h1 class="cyber-title glitch">{title}</h1>
            <div class="cyber-subtitle">
                <p>Timestamp: {timestamp}</p>
                <p>Target: {target}</p>
                <p>Operator: {operator}</p>
            </div>
        </div>
        
        <div class="cyber-section">
            <h2>🎯 EXECUTIVE SUMMARY</h2>
            {executive_summary}
        </div>
        
        <div class="cyber-section">
            <h2>🔍 TECHNICAL FINDINGS</h2>
            {technical_findings}
        </div>
        
        <div class="cyber-section">
            <h2>⚠️ THREAT ANALYSIS</h2>
            {threat_analysis}
        </div>
        
        <div class="visualization-container">
            <h2>📊 VISUAL INTELLIGENCE</h2>
            {visualizations}
        </div>
        
        <div class="cyber-section">
            <h2>✅ RECOMMENDATIONS</h2>
            {recommendations}
        </div>
        
        <div class="cyber-section">
            <h2>💾 RAW DATA</h2>
            {raw_data}
        </div>
        
        <div class="footer">
            <p>Generated by CYBERGHOST OSINT v5.0 | Leonardo Pereira Pinheiro</p>
            <p>FOR ETHICAL AND LEGAL USE ONLY</p>
        </div>
    </div>
    
    <script>
        // Matrix effect
        const chars = "01";
        const matrixContainers = document.querySelectorAll('.matrix-effect');
        
        matrixContainers.forEach(container => {{
            let text = container.textContent;
            let newText = '';
            
            for(let i = 0; i < text.length; i++) {{
                if(text[i] === ' ' || text[i] === '\\n') {{
                    newText += text[i];
                }} else {{
                    newText += chars[Math.floor(Math.random() * chars.length)];
                }}
            }}
            
            container.textContent = newText;
        }});
        
        // Glitch effect
        setInterval(() => {{
            document.querySelectorAll('.glitch').forEach(el => {{
                el.style.animation = 'none';
                setTimeout(() => {{
                    el.style.animation = 'glitch 5s infinite';
                }}, 10);
            }});
        }}, 10000);
    </script>
</body>
</html>"""
    
    # ========== GERADORES DE CONTEÚDO ==========
    
    def _generate_executive_summary(self, data: Dict) -> str:
        """Gera resumo executivo hacker"""
        target = data.get("target", "Unknown")
        threat_level = data.get("intelligence", {}).get("threat_assessment", {}).get("level", "UNKNOWN")
        
        # Métricas
        recon = data.get("recon_data", {})
        subdomains = recon.get("enumerate_subdomains", {}).get("total_found", 0)
        open_ports = recon.get("port_scanning", {}).get("total_open", 0)
        vulnerabilities = len(recon.get("port_scanning", {}).get("vulnerable_services", []))
        
        summary = f"""
        <div class="cyber-metrics">
            <div class="cyber-metric">
                <div class="value">{subdomains}</div>
                <div class="label">Subdomains</div>
            </div>
            <div class="cyber-metric">
                <div class="value">{open_ports}</div>
                <div class="label">Open Ports</div>
            </div>
            <div class="cyber-metric">
                <div class="value">{vulnerabilities}</div>
                <div class="label">Vulnerabilities</div>
            </div>
            <div class="cyber-metric">
                <div class="value risk-{threat_level.lower()}">{threat_level}</div>
                <div class="label">Threat Level</div>
            </div>
        </div>
        
        <p>Target <strong>{target}</strong> has been analyzed using advanced CyberGhost reconnaissance techniques.</p>
        <p>Threat assessment indicates <span class="risk-{threat_level.lower()}">{threat_level}</span> risk level.</p>
        """
        
        return summary
    
    def _generate_technical_findings(self, data: Dict) -> str:
        """Gera achados técnicos"""
        recon = data.get("recon_data", {})
        
        findings = "<h3>🔐 Security Assessment</h3>"
        
        # Subdomains
        subs = recon.get("enumerate_subdomains", {})
        if subs.get("total_found", 0) > 0:
            findings += f"<p>Found <strong>{subs['total_found']}</strong> subdomains</p>"
        
        # Open Ports
        ports = recon.get("port_scanning", {})
        if ports.get("total_open", 0) > 0:
            findings += f"<p><strong>{ports['total_open']}</strong> open ports detected</p>"
            
            # Vulnerable services
            vuln = ports.get("vulnerable_services", [])
            if vuln:
                findings += f"<p><span class='risk-high'>{len(vuln)} vulnerable services</span> identified</p>"
        
        # Technologies
        tech = recon.get("technology_fingerprinting", {})
        if tech:
            tech_count = sum(len(v) for v in tech.values() if isinstance(v, list))
            findings += f"<p><strong>{tech_count}</strong> technologies fingerprinted</p>"
        
        return findings
    
    def _generate_threat_analysis(self, data: Dict) -> str:
        """Gera análise de ameaças"""
        intel = data.get("intelligence", {})
        threat = intel.get("threat_assessment", {})
        
        analysis = f"""
        <table class="cyber-table">
            <tr>
                <th>Threat Level</th>
                <td class="risk-{threat.get('level', 'info').lower()}">{threat.get('level', 'N/A')}</td>
            </tr>
            <tr>
                <th>Risk Score</th>
                <td>{threat.get('score', 'N/A')}/10</td>
            </tr>
            <tr>
                <th>Confidence</th>
                <td>{intel.get('confidence_score', 'N/A')*100}%</td>
            </tr>
        </table>
        """
        
        # Fatores de risco
        factors = threat.get("factors", [])
        if factors:
            analysis += "<h4>Risk Factors:</h4><ul>"
            for factor in factors:
                analysis += f"<li>{factor}</li>"
            analysis += "</ul>"
        
        return analysis
    
    def _generate_recommendations(self, data: Dict) -> str:
        """Gera recomendações"""
        intel = data.get("intelligence", {})
        recommendations = intel.get("recommendations", [])
        
        if not recommendations:
            return "<p>No specific recommendations available.</p>"
        
        html = "<table class='cyber-table'><tr><th>Priority</th><th>Recommendation</th><th>Source</th></tr>"
        
        for rec in recommendations:
            priority = rec.get("priority", "MEDIUM").lower()
            html += f"""
            <tr>
                <td class="risk-{priority}">{rec.get('priority', 'MEDIUM')}</td>
                <td>{rec.get('recommendation', 'N/A')}</td>
                <td>{rec.get('source', 'System')}</td>
            </tr>
            """
        
        html += "</table>"
        return html
    
    def _embed_visualizations(self, figures: Dict) -> str:
        """Embute visualizações"""
        html = ""
        for name, fig in figures.items():
            if hasattr(fig, 'to_html'):
                html += f"<h3>{name.replace('_', ' ').upper()}</h3>"
                html += fig.to_html(full_html=False, include_plotlyjs='cdn')
        return html

# =============================================================================
# APLICAÇÃO PRINCIPAL CYBERGHOST
# =============================================================================

class CyberGhostOSINT:
    """Aplicação principal do CyberGhost OSINT"""
    
    def __init__(self, config_path: Optional[str] = None):
        # Inicializa colorama
        colorama_init(autoreset=True, strip=False)
        
        # Carrega configuração
        self.config = self._load_config(config_path)
        
        # Inicializa componentes
        self.logger = CyberGhostLogger("CyberGhost")
        self.cache = GhostCache(encryption_key=self.config.get("encryption_key", "cyberghost"))
        self.recon = GhostRecon(self.logger, self.cache)
        self.ai = GhostAI(self.config)
        self.visualizer = GhostVisualizer()
        self.reporter = GhostReporter(self.visualizer)
        
        # Status da operação
        self.operation_active = False
        self.targets_scanned = 0
        
        # Banner inicial
        self._print_cyber_banner()
    
    def _load_config(self, config_path: Optional[str]) -> Dict:
        """Carrega configuração"""
        config = CYBERGHOST_CONFIG.copy()
        
        if config_path and Path(config_path).exists():
            try:
                with open(config_path, 'r') as f:
                    if config_path.endswith(('.yaml', '.yml')):
                        user_config = yaml.safe_load(f)
                    elif config_path.endswith('.toml'):
                        user_config = tomli.load(f)
                    else:
                        user_config = json.load(f)
                
                # Merge recursivo
                def deep_update(source, overrides):
                    for key, value in overrides.items():
                        if key in source and isinstance(source[key], dict) and isinstance(value, dict):
                            deep_update(source[key], value)
                        else:
                            source[key] = value
                
                deep_update(config, user_config)
                
            except Exception as e:
                self.logger.log("error", f"Failed to load config: {e}")
        
        return config
    
    def _print_cyber_banner(self):
        """Imprime banner cyberpunk"""
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
║{Fore.GREEN}                     Developed by: Leonardo Pereira Pinheiro                        {Fore.CYAN}║
║{Fore.CYAN}                      Alias: CyberGhost | Codename: Shadow Warrior                   {Fore.CYAN}║
║{Fore.RED}                       WARNING: For Ethical and Legal Use Only!                       {Fore.CYAN}║
║{Fore.CYAN}                                                                                     {Fore.CYAN}║
╚══════════════════════════════════════════════════════════════════════════════════╝{Style.RESET_ALL}
        """
        
        print(banner)
        
        # Matrix effect
        self.logger.print_matrix_effect("INITIALIZING CYBERGHOST OSINT SYSTEM", 0.03)
    
    async def ghost_scan(self, target: str, mode: str = "stealth") -> Dict:
        """Executa scan no modo CyberGhost"""
        self.operation_active = True
        self.targets_scanned += 1
        
        self.logger.print_status(target, "INITIATING", f"Mode: {mode.upper()}")
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
            reports = await self.reporter.generate_report(full_data, style=mode)
            
            # Log de conclusão
            threat_level = intel_data.get("risk_prediction", {}).get("level", "UNKNOWN")
            self.logger.print_status(target, "COMPLETE", f"Threat: {threat_level}")
            self.logger.log("success", f"Ghost scan completed for {target}")
            
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
        finally:
            self.operation_active = False
    
    def _print_scan_summary(self, data: Dict, reports: Dict[str, Path]):
        """Imprime resumo do scan"""
        target = data.get("target", "Unknown")
        threat = data.get("intelligence", {}).get("risk_prediction", {})
        
        print(f"\n{Fore.CYAN}{'═'*70}")
        print(f"{Fore.GREEN} CYBERGHOST SCAN SUMMARY - {target}")
        print(f"{Fore.CYAN}{'═'*70}{Style.RESET_ALL}")
        
        # Métricas
        recon = data.get("recon_data", {})
        metrics = [
            ["Target", target],
            ["Threat Level", f"{threat.get('level', 'N/A')} ({threat.get('score', 'N/A')}/10)"],
            ["Subdomains", recon.get("enumerate_subdomains", {}).get("total_found", 0)],
            ["Open Ports", recon.get("port_scanning", {}).get("total_open", 0)],
            ["Vulnerabilities", len(recon.get("port_scanning", {}).get("vulnerable_services", []))],
            ["Technologies", len(recon.get("technology_fingerprinting", {}))],
            ["Confidence", f"{data.get('intelligence', {}).get('confidence_score', 0)*100:.1f}%"]
        ]
        
        print(tabulate(metrics, tablefmt="grid"))
        
        # Relatórios
        print(f"\n{Fore.CYAN}Reports Generated:{Style.RESET_ALL}")
        for fmt, path in reports.items():
            print(f"  {Fore.GREEN}•{Style.RESET_ALL} {fmt.upper()}: {path}")
        
        # Recomendações
        recommendations = data.get("intelligence", {}).get("recommendations", [])
        if recommendations:
            print(f"\n{Fore.YELLOW}Top Recommendations:{Style.RESET_ALL}")
            for rec in recommendations[:3]:
                print(f"  {Fore.CYAN}→{Style.RESET_ALL} {rec.get('recommendation', '')}")
        
        print(f"\n{Fore.CYAN}{'═'*70}{Style.RESET_ALL}")
    
    async def ghost_batch(self, targets_file: str, concurrent: int = 3):
        """Scans em batch"""
        with open(targets_file, 'r') as f:
            targets = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        
        self.logger.log("info", f"Starting batch scan of {len(targets)} targets")
        
        results = {}
        semaphore = asyncio.Semaphore(concurrent)
        
        async def scan_target(target: str):
            async with semaphore:
                return target, await self.ghost_scan(target)
        
        # Barra de progresso
        with tqdm(total=len(targets), desc="CyberGhost Batch", 
                 bar_format="{l_bar}{bar}| {n_fmt}/{total_fmt} targets") as pbar:
            
            tasks = [scan_target(target) for target in targets]
            for task in asyncio.as_completed(tasks):
                target, result = await task
                results[target] = result
                pbar.update(1)
                
                if result.get("success"):
                    pbar.set_postfix_str(f"✓ {target}")
                else:
                    pbar.set_postfix_str(f"✗ {target}")
        
        # Relatório consolidado
        await self._generate_batch_report(results)
        
        return results
    
    async def ghost_monitor(self, target: str, interval: int = 3600, 
                           duration: int = 86400):
        """Monitoramento contínuo"""
        self.logger.log("stealth", f"Starting ghost monitor on {target}")
        
        observations = []
        start_time = datetime.now()
        
        while (datetime.now() - start_time).seconds < duration:
            try:
                self.logger.print_status(target, "MONITORING", 
                                       f"Check {len(observations) + 1}")
                
                result = await self.ghost_scan(target, "stealth")
                observations.append({
                    "timestamp": datetime.now().isoformat(),
                    "data": result.get("data", {})
                })
                
                # Detectar mudanças
                if len(observations) > 1:
                    changes = self._detect_changes(
                        observations[-2]["data"],
                        observations[-1]["data"]
                    )
                    
                    if changes:
                        self.logger.log("warning", f"Changes detected: {len(changes)}")
                        await self._alert_changes(target, changes)
                
                # Aguarda próximo ciclo
                await asyncio.sleep(interval)
                
            except KeyboardInterrupt:
                self.logger.log("info", "Monitor interrupted by user")
                break
            except Exception as e:
                self.logger.log("error", f"Monitor error: {e}")
                await asyncio.sleep(60)
        
        return observations
    
    def _detect_changes(self, old_data: Dict, new_data: Dict) -> List[Dict]:
        """Detecta mudanças entre scans"""
        changes = []
        
        # Subdomínios
        old_subs = set(old_data.get("recon_data", {}).get("enumerate_subdomains", {}).get("validated", []))
        new_subs = set(new_data.get("recon_data", {}).get("enumerate_subdomains", {}).get("validated", []))
        
        added = new_subs - old_subs
        removed = old_subs - new_subs
        
        if added:
            changes.append({
                "type": "SUBDOMAIN_ADDED",
                "count": len(added),
                "details": list(added)[:3]
            })
        
        if removed:
            changes.append({
                "type": "SUBDOMAIN_REMOVED",
                "count": len(removed),
                "details": list(removed)[:3]
            })
        
        # Portas
        old_ports = set(old_data.get("recon_data", {}).get("port_scanning", {}).get("open_ports", {}).keys())
        new_ports = set(new_data.get("recon_data", {}).get("port_scanning", {}).get("open_ports", {}).keys())
        
        if old_ports != new_ports:
            changes.append({
                "type": "PORT_CHANGE",
                "old": list(old_ports),
                "new": list(new_ports)
            })
        
        return changes
    
    async def _alert_changes(self, target: str, changes: List[Dict]):
        """Alertas de mudanças"""
        alert_msg = f"🔔 CYBERGHOST ALERT: Changes detected on {target}\n\n"
        
        for change in changes:
            alert_msg += f"• {change['type']}: {change.get('count', 'N/A')}\n"
            if 'details' in change:
                alert_msg += f"  Details: {change['details']}\n"
        
        print(f"\n{Fore.RED}{'!'*70}")
        print(alert_msg)
        print(f"{'!'*70}{Style.RESET_ALL}")
    
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
            "results": results
        }
        
        filename = f"cyberghost_batch_{datetime.now():%Y%m%d_%H%M%S}.json"
        filepath = Path("reports") / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, default=str)
        
        self.logger.log("success", f"Batch report saved: {filepath}")

# =============================================================================
# INTERFACE DE COMANDOS CYBERGHOST
# =============================================================================

async def main():
    """Função principal"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="CYBERGHOST OSINT v5.0 - Advanced Cyber Intelligence Platform",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
{Fore.CYAN}╔══════════════════════════════════════════════════════════════════════════════════╗
║                             EXAMPLES                                                     ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                  ║
║ {Fore.GREEN}Single Target Scan:{Style.RESET_ALL}                                               ║
║   cyberghost scan example.com --mode stealth                                      ║
║   cyberghost scan google.com --mode assault --output html,json                    ║
║                                                                                  ║
║ {Fore.GREEN}Batch Scan:{Style.RESET_ALL}                                                       ║
║   cyberghost batch targets.txt --concurrent 5                                     ║
║   cyberghost batch domains.txt --config myconfig.yaml                            ║
║                                                                                  ║
║ {Fore.GREEN}Continuous Monitoring:{Style.RESET_ALL}                                             ║
║   cyberghost monitor critical-site.com --interval 1800 --duration 86400          ║
║                                                                                  ║
║ {Fore.GREEN}Forensic Mode:{Style.RESET_ALL}                                                    ║
║   cyberghost scan hacked-site.com --mode forensic --output all                   ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝

{Fore.YELLOW}Developer: Leonardo Pereira Pinheiro | Alias: CyberGhost{Style.RESET_ALL}
{Fore.RED}Warning: Use only for ethical and legal purposes!{Style.RESET_ALL}
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='CyberGhost Commands')
    
    # Scan command
    scan_parser = subparsers.add_parser('scan', help='Scan single target')
    scan_parser.add_argument('target', help='Target domain or IP')
    scan_parser.add_argument('--mode', choices=[m.value for m in CyberGhostMode], 
                           default='stealth', help='Scan mode')
    scan_parser.add_argument('--output', default='html,txt', 
                           help='Output formats (comma-separated)')
    scan_parser.add_argument('--config', help='Configuration file')
    
    # Batch command
    batch_parser = subparsers.add_parser('batch', help='Batch scan')
    batch_parser.add_argument('file', help='File with targets (one per line)')
    batch_parser.add_argument('--concurrent', type=int, default=3,
                            help='Concurrent scans')
    batch_parser.add_argument('--config', help='Configuration file')
    
    # Monitor command
    monitor_parser = subparsers.add_parser('monitor', help='Continuous monitoring')
    monitor_parser.add_argument('target', help='Target to monitor')
    monitor_parser.add_argument('--interval', type=int, default=3600,
                              help='Check interval in seconds')
    monitor_parser.add_argument('--duration', type=int, default=86400,
                              help='Total duration in seconds')
    monitor_parser.add_argument('--config', help='Configuration file')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    # Inicializa CyberGhost
    ghost = CyberGhostOSINT(args.config)
    
    try:
        if args.command == 'scan':
            await ghost.ghost_scan(args.target, args.mode)
            
        elif args.command == 'batch':
            await ghost.ghost_batch(args.file, args.concurrent)
            
        elif args.command == 'monitor':
            await ghost.ghost_monitor(args.target, args.interval, args.duration)
            
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}[!] Operation terminated by user{Style.RESET_ALL}")
    except Exception as e:
        print(f"\n{Fore.RED}[!] CyberGhost Error: {e}{Style.RESET_ALL}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())