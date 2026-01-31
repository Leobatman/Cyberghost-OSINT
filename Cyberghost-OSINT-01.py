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
║   CYBERGHOST OSINT v5.0 - Advanced Offensive Security Framework                   ║
║   Developed by: Leonardo Pereira Pinheiro                                          ║
║   Code: Shadow Warrior | Alias: CyberGhost                                        ║
║   License: GPL-3.0 | Ethical and Legal Use Required                               ║
║                                                                                    ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"""

# =============================================================================
# CORE IMPORTS - OFFSEC EDITION
# =============================================================================
import asyncio
import aiohttp
import aiofiles
import sys
import os
import json
import yaml
import logging
import hashlib
import pickle
import base64
import uuid
import secrets
import random
import string
import socket
import ssl
import re
import time
import ipaddress
import subprocess
import platform
import threading
import queue
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple, Set
from pathlib import Path
from urllib.parse import urlparse, urljoin, quote, unquote
from dataclasses import dataclass, field, asdict
from enum import Enum, auto
from collections import defaultdict, Counter
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, as_completed
import warnings
warnings.filterwarnings('ignore')

# =============================================================================
# DEPENDENCY MANAGER - AUTO INSTALLATION
# =============================================================================

def install_dependencies():
    """Auto-install required dependencies"""
    required_packages = [
        'aiohttp>=3.8.0',
        'aiofiles>=23.0.0',
        'requests>=2.28.0',
        'beautifulsoup4>=4.11.0',
        'colorama>=0.4.6',
        'tabulate>=0.9.0',
        'tqdm>=4.65.0',
        'pandas>=2.0.0',
        'numpy>=1.24.0',
        'dnspython>=2.3.0',
        'python-whois>=0.8.0',
        'builtwith>=1.3.3',
        'argparse>=1.4.0',
        'pyyaml>=6.0',
        'cryptography>=41.0.0',
        'psutil>=5.9.0',
        'scapy>=2.5.0',
        'paramiko>=3.0.0',
        'python-nmap>=0.7.1',
        'urllib3>=1.26.0',
        'lxml>=4.9.0',
        'certifi>=2023.5.7'
    ]
    
    optional_packages = [
        'openai>=0.27.0',
        'shodan>=1.28.0',
        'censys>=2.0.0',
        'transformers>=4.30.0',
        'torch>=2.0.0',
        'spacy>=3.5.0',
        'plotly>=5.14.0',
        'matplotlib>=3.7.0',
        'seaborn>=0.12.0',
        'networkx>=3.0',
        'redis>=4.5.0',
        'bcrypt>=4.0.0',
        'scikit-learn>=1.3.0',
        'Pillow>=10.0.0'
    ]
    
    print("[+] Checking dependencies...")
    
    import subprocess
    import importlib.util
    
    def is_installed(package):
        """Check if package is installed"""
        try:
            spec = importlib.util.find_spec(package.split('>=')[0].split('==')[0])
            return spec is not None
        except:
            return False
    
    missing = []
    for package in required_packages:
        pkg_name = package.split('>=')[0].split('==')[0]
        if not is_installed(pkg_name):
            missing.append(package)
    
    if missing:
        print(f"[!] Installing missing dependencies: {len(missing)} packages")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade"] + missing)
            print("[+] Dependencies installed successfully!")
        except Exception as e:
            print(f"[-] Failed to install dependencies: {e}")
            print("[!] Please install manually: pip install " + " ".join(missing))
            sys.exit(1)
    else:
        print("[+] All dependencies are already installed!")

# Try to install dependencies
try:
    install_dependencies()
except:
    print("[!] Continuing without auto-installation")

# =============================================================================
# DYNAMIC IMPORTS - WITH ERROR HANDLING
# =============================================================================

# Core imports (should always be available after install)
import aiohttp
import aiofiles
import requests
from bs4 import BeautifulSoup
from colorama import Fore, Style, Back, init as colorama_init
from tabulate import tabulate
from tqdm.auto import tqdm
import pandas as pd
import numpy as np
import dns.resolver
import dns.asyncresolver
import dns.reversename
import whois
import builtwith
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Optional imports with fallbacks
try:
    import nmap
    NMAP_AVAILABLE = True
except ImportError:
    nmap = None
    NMAP_AVAILABLE = False

try:
    import scapy.all as scapy
    from scapy.all import ARP, Ether, srp, IP, TCP, UDP, ICMP, sr1
    SCAPY_AVAILABLE = True
except ImportError:
    scapy = None
    SCAPY_AVAILABLE = False

try:
    import paramiko
    PARAMIKO_AVAILABLE = True
except ImportError:
    paramiko = None
    PARAMIKO_AVAILABLE = False

try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    psutil = None
    PSUTIL_AVAILABLE = False

try:
    from cryptography.fernet import Fernet
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.backends import default_backend
    CRYPTOGRAPHY_AVAILABLE = True
except ImportError:
    CRYPTOGRAPHY_AVAILABLE = False

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
    import plotly.graph_objects as go
    import plotly.express as px
    PLOTLY_AVAILABLE = True
except ImportError:
    PLOTLY_AVAILABLE = False

try:
    import matplotlib.pyplot as plt
    import seaborn as sns
    MATPLOTLIB_AVAILABLE = True
except ImportError:
    MATPLOTLIB_AVAILABLE = False

# Initialize colorama
colorama_init(autoreset=True)

# =============================================================================
# CONFIGURATION SYSTEM
# =============================================================================

class Config:
    """Centralized configuration management"""
    
    DEFAULT_CONFIG = {
        "version": "5.0",
        "author": "Leonardo Pereira Pinheiro",
        "alias": "CyberGhost",
        "codename": "Shadow Warrior",
        
        "network": {
            "timeout": 30,
            "max_retries": 3,
            "concurrent_requests": 50,
            "user_agents": [
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0",
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            ],
            "proxies": [],
            "tor_proxy": "socks5://127.0.0.1:9050"
        },
        
        "scanning": {
            "port_ranges": {
                "quick": "1-1024",
                "standard": "1-10000",
                "full": "1-65535",
                "web": "80,443,8080,8443,3000,8000"
            },
            "rate_limit": 100,  # packets per second
            "stealth_mode": True,
            "os_detection": True,
            "service_version": True
        },
        
        "wordlists": {
            "subdomains": "wordlists/subdomains.txt",
            "directories": "wordlists/directories.txt",
            "passwords": "wordlists/passwords.txt",
            "usernames": "wordlists/usernames.txt"
        },
        
        "api_keys": {
            "shodan": "",
            "censys": "",
            "virustotal": "",
            "hunterio": "",
            "openai": ""
        },
        
        "output": {
            "reports_dir": "reports",
            "evidence_dir": "evidence",
            "logs_dir": "logs",
            "formats": ["html", "json", "txt", "pdf"],
            "encrypt_reports": False
        },
        
        "modules": {
            "recon": True,
            "vuln_scan": True,
            "exploitation": True,
            "post_exploit": True,
            "reporting": True
        }
    }
    
    @staticmethod
    def load(config_path: Optional[str] = None) -> Dict:
        """Load configuration from file or use defaults"""
        config = Config.DEFAULT_CONFIG.copy()
        
        if config_path and Path(config_path).exists():
            try:
                with open(config_path, 'r') as f:
                    if config_path.endswith(('.yaml', '.yml')):
                        import yaml
                        user_config = yaml.safe_load(f)
                    elif config_path.endswith('.json'):
                        user_config = json.load(f)
                    else:
                        # Try different formats
                        try:
                            user_config = json.load(f)
                        except:
                            f.seek(0)
                            user_config = yaml.safe_load(f)
                
                # Deep merge
                def merge_dicts(base, override):
                    for key, value in override.items():
                        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                            merge_dicts(base[key], value)
                        else:
                            base[key] = value
                
                merge_dicts(config, user_config)
                print(f"[+] Configuration loaded from {config_path}")
                
            except Exception as e:
                print(f"[-] Failed to load config: {e}")
        
        # Create directories
        for dir_key in ['reports_dir', 'evidence_dir', 'logs_dir']:
            dir_path = Path(config['output'][dir_key])
            dir_path.mkdir(parents=True, exist_ok=True)
        
        # Create wordlists directory
        wordlists_dir = Path("wordlists")
        wordlists_dir.mkdir(exist_ok=True)
        
        return config

# =============================================================================
# LOGGING SYSTEM - ADVANCED
# =============================================================================

class Logger:
    """Advanced logging system with multiple outputs"""
    
    LOG_LEVELS = {
        'DEBUG': 0,
        'INFO': 1,
        'WARNING': 2,
        'ERROR': 3,
        'CRITICAL': 4
    }
    
    COLORS = {
        'DEBUG': Fore.CYAN,
        'INFO': Fore.GREEN,
        'WARNING': Fore.YELLOW,
        'ERROR': Fore.RED,
        'CRITICAL': Fore.MAGENTA + Style.BRIGHT,
        'SUCCESS': Fore.GREEN + Style.BRIGHT,
        'HACK': Fore.MAGENTA,
        'STEALTH': Fore.CYAN + Style.DIM
    }
    
    def __init__(self, name: str = "CyberGhost", level: str = "INFO"):
        self.name = name
        self.level = self.LOG_LEVELS.get(level.upper(), 1)
        self.session_id = f"{datetime.now():%Y%m%d%H%M%S}_{secrets.token_hex(4)}"
        
        # Setup file logging
        self.log_dir = Path("logs")
        self.log_dir.mkdir(exist_ok=True)
        
        self.log_file = self.log_dir / f"cyberghost_{self.session_id}.log"
        self.json_log_file = self.log_dir / f"cyberghost_{self.session_id}.jsonl"
        
        # Setup console logging
        self._setup_handlers()
        
        # Statistics
        self.stats = Counter()
    
    def _setup_handlers(self):
        """Setup logging handlers"""
        # File handler (text)
        self.file_handler = logging.FileHandler(self.log_file, encoding='utf-8')
        self.file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        self.file_handler.setFormatter(file_formatter)
        
        # Console handler
        self.console_handler = logging.StreamHandler()
        self.console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter('%(message)s')
        self.console_handler.setFormatter(console_formatter)
        
        # Create logger
        self.logger = logging.getLogger(self.name)
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(self.file_handler)
        self.logger.addHandler(self.console_handler)
        
        # Disable propagation
        self.logger.propagate = False
    
    def log(self, level: str, message: str, module: str = "CORE", data: Dict = None):
        """Log message with level"""
        level_num = self.LOG_LEVELS.get(level.upper(), 1)
        
        if level_num < self.level:
            return
        
        # Update statistics
        self.stats[level.upper()] += 1
        
        # Color and icon
        color = self.COLORS.get(level.upper(), Fore.WHITE)
        icons = {
            'DEBUG': '🔧',
            'INFO': 'ℹ️',
            'WARNING': '⚠️',
            'ERROR': '❌',
            'CRITICAL': '💀',
            'SUCCESS': '✅',
            'HACK': '⚡',
            'STEALTH': '👻'
        }
        icon = icons.get(level.upper(), '📝')
        
        # Format message
        timestamp = datetime.now().strftime('%H:%M:%S')
        formatted_msg = f"{color}[{timestamp}] {icon} [{module}] {message}{Style.RESET_ALL}"
        
        # Log to file with more details
        file_msg = f"[{timestamp}] {level.upper():8} | {module:15} | {message}"
        if data:
            file_msg += f" | {json.dumps(data)[:200]}"
        
        if level.upper() == 'DEBUG':
            self.logger.debug(file_msg)
        elif level.upper() == 'INFO':
            self.logger.info(file_msg)
        elif level.upper() == 'WARNING':
            self.logger.warning(file_msg)
        elif level.upper() == 'ERROR':
            self.logger.error(file_msg)
        elif level.upper() == 'CRITICAL':
            self.logger.critical(file_msg)
        else:
            self.logger.info(file_msg)
        
        # Also print to console for custom levels
        if level.upper() in ['SUCCESS', 'HACK', 'STEALTH']:
            print(formatted_msg)
        
        # Save to JSON log
        if data or level.upper() in ['SUCCESS', 'HACK', 'STEALTH']:
            self._save_json_log(level, message, module, data)
    
    def _save_json_log(self, level: str, message: str, module: str, data: Dict):
        """Save structured log to JSONL file"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": level.upper(),
            "module": module,
            "message": message,
            "session_id": self.session_id,
            "data": data or {}
        }
        
        try:
            with open(self.json_log_file, 'a', encoding='utf-8') as f:
                f.write(json.dumps(log_entry) + '\n')
        except:
            pass
    
    def banner(self):
        """Display CyberGhost banner"""
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
║{Fore.YELLOW}                    CYBERGHOST OSINT v5.0 - Offensive Security Suite              {Fore.CYAN}║
║{Fore.GREEN}                     Developed by: Leonardo Pereira Pinheiro                        {Fore.CYAN}║
║{Fore.CYAN}                      Alias: CyberGhost | Codename: Shadow Warrior                   {Fore.CYAN}║
║{Fore.RED}                       WARNING: For Authorized Penetration Testing Only!             {Fore.CYAN}║
╚══════════════════════════════════════════════════════════════════════════════════╝{Style.RESET_ALL}
        """
        
        print(banner)
        print(f"{Fore.GREEN}[+] Session ID: {self.session_id}")
        print(f"[+] Start Time: {datetime.now():%Y-%m-%d %H:%M:%S}")
        print(f"[+] System: {platform.system()} {platform.release()}")
        print(f"[+] Python: {platform.python_version()}")
        print(f"{Fore.CYAN}{'='*80}{Style.RESET_ALL}\n")
    
    def status(self, target: str, status: str, details: str = ""):
        """Display status update"""
        status_colors = {
            'SCANNING': Fore.BLUE,
            'ANALYZING': Fore.CYAN,
            'EXPLOITING': Fore.MAGENTA,
            'COMPROMISED': Fore.RED,
            'SECURE': Fore.GREEN,
            'VULNERABLE': Fore.YELLOW,
            'COMPLETE': Fore.GREEN + Style.BRIGHT
        }
        
        color = status_colors.get(status, Fore.WHITE)
        print(f"\n{Fore.CYAN}[{datetime.now().strftime('%H:%M:%S')}] "
              f"{color}▶{Style.RESET_ALL} {status:12} → {Fore.YELLOW}{target}{Style.RESET_ALL}")
        
        if details:
            print(f"   └─ {details}")

# =============================================================================
# NETWORK UTILITIES
# =============================================================================

class NetworkUtils:
    """Network utility functions"""
    
    @staticmethod
    def get_random_user_agent() -> str:
        """Get random user agent"""
        user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.0.0'
        ]
        return random.choice(user_agents)
    
    @staticmethod
    def is_valid_ip(ip: str) -> bool:
        """Check if string is valid IP address"""
        try:
            ipaddress.ip_address(ip)
            return True
        except ValueError:
            return False
    
    @staticmethod
    def is_valid_domain(domain: str) -> bool:
        """Check if string is valid domain"""
        pattern = r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
        return bool(re.match(pattern, domain))
    
    @staticmethod
    def resolve_hostname(hostname: str) -> List[str]:
        """Resolve hostname to IP addresses"""
        try:
            return socket.gethostbyname_ex(hostname)[2]
        except socket.gaierror:
            return []
    
    @staticmethod
    def get_reverse_dns(ip: str) -> List[str]:
        """Get reverse DNS records for IP"""
        try:
            return socket.gethostbyaddr(ip)[0]
        except socket.herror:
            return []
    
    @staticmethod
    def check_port(host: str, port: int, timeout: float = 2.0) -> bool:
        """Check if port is open"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except:
            return False
    
    @staticmethod
    def get_service_name(port: int, protocol: str = 'tcp') -> str:
        """Get service name for port"""
        try:
            return socket.getservbyport(port, protocol)
        except:
            return "unknown"
    
    @staticmethod
    def get_ssl_certificate(host: str, port: int = 443) -> Optional[Dict]:
        """Get SSL certificate info"""
        try:
            context = ssl.create_default_context()
            with socket.create_connection((host, port), timeout=5) as sock:
                with context.wrap_socket(sock, server_hostname=host) as ssock:
                    cert = ssock.getpeercert()
                    
                    cert_info = {
                        'subject': dict(x[0] for x in cert['subject']),
                        'issuer': dict(x[0] for x in cert['issuer']),
                        'version': cert.get('version'),
                        'serialNumber': cert.get('serialNumber'),
                        'notBefore': cert.get('notBefore'),
                        'notAfter': cert.get('notAfter'),
                        'subjectAltName': cert.get('subjectAltName', []),
                        'OCSP': cert.get('OCSP', []),
                        'caIssuers': cert.get('caIssuers', []),
                    }
                    
                    # Check validity
                    from datetime import datetime
                    not_after = datetime.strptime(cert_info['notAfter'], '%b %d %H:%M:%S %Y %Z')
                    cert_info['valid'] = not_after > datetime.now()
                    cert_info['days_remaining'] = (not_after - datetime.now()).days
                    
                    return cert_info
        except Exception as e:
            return None

# =============================================================================
# ASYNC HTTP CLIENT
# =============================================================================

class AsyncHTTPClient:
    """Asynchronous HTTP client with retry and rate limiting"""
    
    def __init__(self, logger: Logger, max_concurrent: int = 50, retries: int = 3):
        self.logger = logger
        self.max_concurrent = max_concurrent
        self.retries = retries
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.session = None
        self.stats = {
            'requests': 0,
            'success': 0,
            'errors': 0,
            'total_time': 0
        }
    
    async def __aenter__(self):
        """Async context manager entry"""
        timeout = aiohttp.ClientTimeout(total=30)
        connector = aiohttp.TCPConnector(limit=self.max_concurrent, ssl=False)
        self.session = aiohttp.ClientSession(
            timeout=timeout,
            connector=connector,
            headers={'User-Agent': NetworkUtils.get_random_user_agent()}
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    async def request(self, method: str, url: str, **kwargs) -> Optional[aiohttp.ClientResponse]:
        """Make HTTP request with retry logic"""
        start_time = time.time()
        
        for attempt in range(self.retries + 1):
            try:
                async with self.semaphore:
                    async with self.session.request(method, url, **kwargs) as response:
                        self.stats['requests'] += 1
                        self.stats['success'] += 1
                        self.stats['total_time'] += time.time() - start_time
                        return response
            except Exception as e:
                if attempt == self.retries:
                    self.logger.log('WARNING', f"Request failed after {self.retries} retries: {e}", "HTTP")
                    self.stats['errors'] += 1
                    return None
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
        
        return None
    
    async def get(self, url: str, **kwargs) -> Optional[str]:
        """GET request returning text"""
        response = await self.request('GET', url, **kwargs)
        if response and response.status == 200:
            return await response.text()
        return None
    
    async def post(self, url: str, data: Dict = None, **kwargs) -> Optional[Dict]:
        """POST request returning JSON"""
        response = await self.request('POST', url, json=data, **kwargs)
        if response and response.status in [200, 201]:
            try:
                return await response.json()
            except:
                return await response.text()
        return None

# =============================================================================
# RECONNAISSANCE MODULE - COMPLETE
# =============================================================================

class ReconModule:
    """Complete reconnaissance module"""
    
    def __init__(self, logger: Logger, config: Dict):
        self.logger = logger
        self.config = config
        self.cache = {}
        self.wordlists = self._load_wordlists()
        
        # Common ports for scanning
        self.common_ports = {
            'web': [80, 443, 8080, 8443, 3000, 8000, 8888],
            'database': [3306, 5432, 27017, 6379, 9200, 9300, 11211],
            'remote': [22, 23, 3389, 5900, 5985, 5986, 5800],
            'file': [21, 69, 2049, 137, 138, 139, 445],
            'mail': [25, 110, 143, 465, 587, 993, 995],
            'dns': [53],
            'vpn': [1194, 1723, 1701, 500, 4500],
            'special': [1337, 31337, 666, 9999, 12345, 54321]
        }
    
    def _load_wordlists(self) -> Dict[str, List[str]]:
        """Load wordlists from files or use defaults"""
        wordlists = {}
        
        # Default subdomain wordlist
        wordlists['subdomains'] = [
            'www', 'mail', 'ftp', 'ssh', 'admin', 'api', 'dev', 'test',
            'staging', 'prod', 'beta', 'alpha', 'secure', 'portal', 'blog',
            'webmail', 'cpanel', 'whm', 'webdisk', 'ns1', 'ns2', 'ns3',
            'ns4', 'mx', 'mx1', 'mx2', 'autodiscover', 'exchange', 'owa',
            'vpn', 'remote', 'server', 'client', 'app', 'apps', 'cloud',
            'storage', 'cdn', 'dns', 'git', 'svn', 'jenkins', 'docker',
            'kubernetes', 'monitor', 'grafana', 'kibana', 'elastic',
            'redis', 'mysql', 'postgres', 'mongodb', 'oracle', 'sql',
            'backend', 'frontend', 'api-gateway', 'loadbalancer'
        ]
        
        # Default directory wordlist
        wordlists['directories'] = [
            'admin', 'administrator', 'login', 'wp-admin', 'wp-login',
            'dashboard', 'control', 'console', 'manager', 'system',
            'config', 'configuration', 'setup', 'install', 'update',
            'backup', 'backups', 'bak', 'old', 'temp', 'tmp', 'logs',
            'private', 'secret', 'hidden', 'secure', 'api', 'api/v1',
            'api/v2', 'graphql', 'rest', 'soap', 'xmlrpc', 'json',
            'oauth', 'auth', 'authentication', 'sso', 'ldap', 'ad',
            'user', 'users', 'profile', 'profiles', 'account', 'accounts',
            'register', 'registration', 'signup', 'signin', 'logout',
            'password', 'passwd', 'reset', 'recover', 'forgot',
            'search', 'find', 'query', 'filter', 'sort', 'order',
            'upload', 'download', 'export', 'import', 'sync', 'backup',
            'restore', 'recovery', 'debug', 'test', 'testing', 'demo',
            'sample', 'example', 'playground', 'sandbox', 'lab', 'labs',
            'dev', 'development', 'staging', 'production', 'prod', 'live',
            'beta', 'alpha', 'gamma', 'canary', 'release', 'version',
            'v1', 'v2', 'v3', 'latest', 'current', 'new', 'old',
            'archive', 'archives', 'history', 'historic', 'legacy',
            'mobile', 'm', 'wap', 'web', 'www', 'site', 'sites',
            'home', 'index', 'main', 'default', 'start', 'begin',
            'root', 'base', 'core', 'central', 'hub', 'portal',
            'gateway', 'proxy', 'bridge', 'router', 'switch',
            'firewall', 'security', 'secure', 'protected', 'private',
            'public', 'shared', 'common', 'global', 'local',
            'remote', 'external', 'internal', 'intranet', 'extranet',
            'partner', 'partners', 'client', 'clients', 'customer',
            'customers', 'vendor', 'vendors', 'supplier', 'suppliers',
            'employee', 'employees', 'staff', 'team', 'teams',
            'department', 'departments', 'division', 'divisions',
            'branch', 'branches', 'office', 'offices', 'location',
            'locations', 'region', 'regions', 'zone', 'zones',
            'country', 'countries', 'city', 'cities', 'state', 'states',
            'area', 'areas', 'district', 'districts', 'sector', 'sectors',
            'unit', 'units', 'module', 'modules', 'component', 'components',
            'service', 'services', 'resource', 'resources', 'asset', 'assets',
            'document', 'documents', 'file', 'files', 'folder', 'folders',
            'directory', 'directories', 'path', 'paths', 'route', 'routes',
            'url', 'urls', 'link', 'links', 'reference', 'references',
            'source', 'sources', 'destination', 'destinations',
            'target', 'targets', 'goal', 'goals', 'objective', 'objectives',
            'purpose', 'purposes', 'mission', 'missions', 'vision', 'visions',
            'strategy', 'strategies', 'plan', 'plans', 'project', 'projects',
            'task', 'tasks', 'job', 'jobs', 'work', 'works', 'activity',
            'activities', 'operation', 'operations', 'process', 'processes',
            'procedure', 'procedures', 'method', 'methods', 'technique',
            'techniques', 'approach', 'approaches', 'solution', 'solutions',
            'answer', 'answers', 'result', 'results', 'outcome', 'outcomes',
            'output', 'outputs', 'input', 'inputs', 'data', 'database',
            'databases', 'storage', 'storages', 'memory', 'memories',
            'cache', 'caches', 'buffer', 'buffers', 'queue', 'queues',
            'stack', 'stacks', 'heap', 'heaps', 'pool', 'pools',
            'collection', 'collections', 'set', 'sets', 'list', 'lists',
            'array', 'arrays', 'map', 'maps', 'table', 'tables',
            'record', 'records', 'entry', 'entries', 'item', 'items',
            'element', 'elements', 'object', 'objects', 'entity', 'entities',
            'class', 'classes', 'type', 'types', 'kind', 'kinds',
            'category', 'categories', 'group', 'groups', 'family', 'families',
            'species', 'variety', 'varieties', 'form', 'forms',
            'shape', 'shapes', 'size', 'sizes', 'color', 'colors',
            'weight', 'weights', 'height', 'heights', 'width', 'widths',
            'depth', 'depths', 'length', 'lengths', 'distance', 'distances',
            'time', 'times', 'date', 'dates', 'year', 'years',
            'month', 'months', 'week', 'weeks', 'day', 'days',
            'hour', 'hours', 'minute', 'minutes', 'second', 'seconds',
            'millisecond', 'milliseconds', 'microsecond', 'microseconds',
            'nanosecond', 'nanoseconds', 'picosecond', 'picoseconds'
        ]
        
        # Try to load from files
        wordlist_config = self.config.get('wordlists', {})
        
        for list_type, file_path in wordlist_config.items():
            if file_path and Path(file_path).exists():
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        wordlists[list_type] = [line.strip() for line in f if line.strip()]
                    self.logger.log('INFO', f"Loaded wordlist: {list_type} ({len(wordlists[list_type])} entries)")
                except Exception as e:
                    self.logger.log('WARNING', f"Failed to load wordlist {list_type}: {e}")
        
        return wordlists
    
    async def full_reconnaissance(self, target: str) -> Dict:
        """Complete reconnaissance pipeline"""
        self.logger.status(target, "SCANNING", "Starting comprehensive reconnaissance")
        
        results = {
            'target': target,
            'timestamp': datetime.now().isoformat(),
            'recon': {}
        }
        
        # Determine target type
        if NetworkUtils.is_valid_ip(target):
            results['type'] = 'ip'
            results['recon']['host_discovery'] = await self.host_discovery(target)
        elif NetworkUtils.is_valid_domain(target):
            results['type'] = 'domain'
            results['recon']['dns_enumeration'] = await self.dns_enumeration(target)
        else:
            self.logger.log('ERROR', f"Invalid target: {target}")
            return results
        
        # Common reconnaissance tasks
        recon_tasks = [
            ('subdomain_enumeration', self.subdomain_enumeration, target),
            ('port_scanning', self.port_scanning, target),
            ('service_detection', self.service_detection, target),
            ('technology_fingerprinting', self.technology_fingerprinting, target),
            ('web_crawling', self.web_crawling, target),
            ('vulnerability_scan', self.vulnerability_scan, target)
        ]
        
        # Execute tasks concurrently
        tasks = []
        for name, func, arg in recon_tasks:
            task = asyncio.create_task(self._execute_recon_task(name, func, arg))
            tasks.append((name, task))
        
        # Collect results
        for name, task in tasks:
            try:
                results['recon'][name] = await task
                self.logger.log('SUCCESS', f"Completed: {name}")
            except Exception as e:
                self.logger.log('ERROR', f"Failed {name}: {e}")
                results['recon'][name] = {'error': str(e)}
        
        # Generate intelligence report
        results['intelligence'] = await self.generate_intelligence_report(results['recon'])
        
        self.logger.status(target, "COMPLETE", "Reconnaissance finished")
        return results
    
    async def _execute_recon_task(self, name: str, func, arg):
        """Execute reconnaissance task with timing"""
        start_time = time.time()
        result = await func(arg) if asyncio.iscoroutinefunction(func) else func(arg)
        elapsed = time.time() - start_time
        return {'data': result, 'time_elapsed': elapsed, 'task': name}
    
    async def subdomain_enumeration(self, domain: str) -> Dict:
        """Enumerate subdomains using multiple techniques"""
        self.logger.log('INFO', f"Enumerating subdomains for {domain}", "SUBDOMAIN")
        
        subdomains = set()
        techniques = {}
        
        # Technique 1: DNS brute force
        techniques['dns_bruteforce'] = await self._dns_bruteforce(domain)
        subdomains.update(techniques['dns_bruteforce'])
        
        # Technique 2: Search engine dorking (simulated)
        techniques['search_engines'] = await self._search_engine_dorking(domain)
        subdomains.update(techniques['search_engines'])
        
        # Technique 3: Certificate transparency
        techniques['certificate_transparency'] = await self._certificate_transparency(domain)
        subdomains.update(techniques['certificate_transparency'])
        
        # Technique 4: DNS zone transfers (if possible)
        techniques['zone_transfer'] = await self._dns_zone_transfer(domain)
        subdomains.update(techniques['zone_transfer'])
        
        # Technique 5: Reverse DNS lookup on IP ranges
        techniques['reverse_dns'] = await self._reverse_dns_lookup(domain)
        subdomains.update(techniques['reverse_dns'])
        
        # Validate subdomains
        validated = await self._validate_subdomains(domain, list(subdomains))
        
        # Categorize by service type
        categorized = self._categorize_subdomains(validated)
        
        return {
            'total_found': len(subdomains),
            'validated': validated,
            'categorized': categorized,
            'techniques': {k: len(v) for k, v in techniques.items()}
        }
    
    async def _dns_bruteforce(self, domain: str) -> List[str]:
        """DNS brute force enumeration"""
        found = []
        wordlist = self.wordlists.get('subdomains', [])
        
        async def check_subdomain(sub: str):
            full_domain = f"{sub}.{domain}"
            try:
                resolver = dns.asyncresolver.Resolver()
                resolver.timeout = 2
                resolver.lifetime = 2
                await resolver.resolve(full_domain, 'A')
                return full_domain
            except:
                return None
        
        # Use asyncio.gather for concurrent lookups
        tasks = []
        for sub in wordlist[:500]:  # Limit for performance
            tasks.append(check_subdomain(sub))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for result in results:
            if result and not isinstance(result, Exception):
                found.append(result)
        
        return found
    
    async def _search_engine_dorking(self, domain: str) -> List[str]:
        """Search engine dorking for subdomains (simulated)"""
        # In a real implementation, this would query search engines
        # For now, return empty list
        return []
    
    async def _certificate_transparency(self, domain: str) -> List[str]:
        """Query certificate transparency logs"""
        subdomains = set()
        
        # Use crt.sh API
        url = f"https://crt.sh/json?q=%25.{domain}"
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=10) as response:
                    if response.status == 200:
                        data = await response.json()
                        for cert in data:
                            name_value = cert.get('name_value', '')
                            names = name_value.split('\n')
                            for name in names:
                                if domain in name and '*' not in name:
                                    subdomains.add(name.strip())
        except:
            pass
        
        return list(subdomains)
    
    async def _dns_zone_transfer(self, domain: str) -> List[str]:
        """Attempt DNS zone transfer"""
        subdomains = []
        
        try:
            # Get name servers
            resolver = dns.resolver.Resolver()
            ns_records = resolver.resolve(domain, 'NS')
            
            for ns in ns_records:
                ns_server = str(ns).rstrip('.')
                
                # Try zone transfer
                try:
                    zone = dns.zone.from_xfr(dns.query.xfr(ns_server, domain))
                    for name in zone:
                        subdomains.append(f"{name}.{domain}")
                except:
                    continue
        except:
            pass
        
        return subdomains
    
    async def _reverse_dns_lookup(self, domain: str) -> List[str]:
        """Reverse DNS lookup on IP ranges"""
        # This would require identifying IP ranges first
        # For now, return empty list
        return []
    
    async def _validate_subdomains(self, domain: str, subdomains: List[str]) -> List[str]:
        """Validate subdomains by resolving them"""
        validated = []
        
        async def validate(sub: str):
            try:
                resolver = dns.asyncresolver.Resolver()
                resolver.timeout = 2
                resolver.lifetime = 2
                await resolver.resolve(sub, 'A')
                return sub
            except:
                return None
        
        # Validate in batches
        batch_size = 50
        for i in range(0, len(subdomains), batch_size):
            batch = subdomains[i:i + batch_size]
            tasks = [validate(sub) for sub in batch]
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            for result in results:
                if result and not isinstance(result, Exception):
                    validated.append(result)
            
            # Small delay to avoid rate limiting
            await asyncio.sleep(0.1)
        
        return validated
    
    def _categorize_subdomains(self, subdomains: List[str]) -> Dict[str, List[str]]:
        """Categorize subdomains by service type"""
        categories = {
            'web': [],
            'mail': [],
            'database': [],
            'infrastructure': [],
            'development': [],
            'cloud': [],
            'other': []
        }
        
        patterns = {
            'web': ['www', 'web', 'site', 'blog', 'portal', 'app', 'apps', 'api'],
            'mail': ['mail', 'smtp', 'pop', 'imap', 'exchange', 'owa', 'mx'],
            'database': ['db', 'mysql', 'postgres', 'mongo', 'redis', 'elastic'],
            'infrastructure': ['ns', 'dns', 'vpn', 'proxy', 'gateway', 'router'],
            'development': ['dev', 'test', 'staging', 'jenkins', 'git', 'svn'],
            'cloud': ['aws', 'azure', 'gcp', 'cloud', 'storage', 'cdn']
        }
        
        for subdomain in subdomains:
            categorized = False
            for category, keywords in patterns.items():
                for keyword in keywords:
                    if keyword in subdomain.lower():
                        categories[category].append(subdomain)
                        categorized = True
                        break
                if categorized:
                    break
            
            if not categorized:
                categories['other'].append(subdomain)
        
        return categories
    
    async def port_scanning(self, target: str) -> Dict:
        """Comprehensive port scanning"""
        self.logger.log('INFO', f"Scanning ports on {target}", "PORTSCAN")
        
        open_ports = {}
        
        # Use different scanning methods
        if NMAP_AVAILABLE:
            open_ports.update(await self._nmap_scan(target))
        elif SCAPY_AVAILABLE:
            open_ports.update(await self._scapy_scan(target))
        else:
            open_ports.update(await self._socket_scan(target))
        
        # Detect service versions
        for port, info in open_ports.items():
            if info.get('state') == 'open':
                service_info = await self._detect_service_version(target, int(port))
                if service_info:
                    info.update(service_info)
        
        # Identify vulnerable services
        vulnerable = self._identify_vulnerable_services(open_ports)
        
        return {
            'open_ports': open_ports,
            'vulnerable_services': vulnerable,
            'total_open': len(open_ports),
            'scan_method': 'nmap' if NMAP_AVAILABLE else 'scapy' if SCAPY_AVAILABLE else 'socket'
        }
    
    async def _nmap_scan(self, target: str) -> Dict:
        """Port scanning using nmap"""
        scanner = nmap.PortScanner()
        
        try:
            # Quick scan of common ports
            port_ranges = ','.join(str(port) for ports in self.common_ports.values() for port in ports)
            scanner.scan(target, arguments=f'-sS -T4 -p {port_ranges}')
            
            open_ports = {}
            for host in scanner.all_hosts():
                for proto in scanner[host].all_protocols():
                    ports = scanner[host][proto].keys()
                    for port in ports:
                        port_info = scanner[host][proto][port]
                        if port_info['state'] == 'open':
                            open_ports[str(port)] = {
                                'state': port_info['state'],
                                'service': port_info.get('name', 'unknown'),
                                'product': port_info.get('product', ''),
                                'version': port_info.get('version', ''),
                                'extrainfo': port_info.get('extrainfo', '')
                            }
            
            return open_ports
        except Exception as e:
            self.logger.log('ERROR', f"Nmap scan failed: {e}")
            return {}
    
    async def _scapy_scan(self, target: str) -> Dict:
        """Port scanning using scapy"""
        open_ports = {}
        
        # Combine all common ports
        all_ports = []
        for ports in self.common_ports.values():
            all_ports.extend(ports)
        
        # Remove duplicates and sort
        all_ports = sorted(set(all_ports))
        
        # Scan in batches
        batch_size = 100
        for i in range(0, len(all_ports), batch_size):
            batch = all_ports[i:i + batch_size]
            
            # SYN scan
            for port in batch:
                try:
                    pkt = IP(dst=target)/TCP(dport=port, flags='S')
                    resp = sr1(pkt, timeout=1, verbose=0)
                    
                    if resp and resp.haslayer(TCP):
                        if resp.getlayer(TCP).flags == 0x12:  # SYN-ACK
                            open_ports[str(port)] = {
                                'state': 'open',
                                'service': NetworkUtils.get_service_name(port)
                            }
                            # Send RST to close connection
                            rst_pkt = IP(dst=target)/TCP(dport=port, flags='R')
                            send(rst_pkt, verbose=0)
                except:
                    continue
            
            # Rate limiting
            await asyncio.sleep(0.1)
        
        return open_ports
    
    async def _socket_scan(self, target: str) -> Dict:
        """Port scanning using raw sockets"""
        open_ports = {}
        
        # Combine all common ports
        all_ports = []
        for ports in self.common_ports.values():
            all_ports.extend(ports)
        
        # Remove duplicates
        all_ports = list(set(all_ports))
        
        # Use ThreadPoolExecutor for concurrent scanning
        with ThreadPoolExecutor(max_workers=100) as executor:
            futures = {executor.submit(NetworkUtils.check_port, target, port): port for port in all_ports}
            
            for future in as_completed(futures):
                port = futures[future]
                try:
                    if future.result():
                        open_ports[str(port)] = {
                            'state': 'open',
                            'service': NetworkUtils.get_service_name(port)
                        }
                except:
                    pass
        
        return open_ports
    
    async def _detect_service_version(self, target: str, port: int) -> Optional[Dict]:
        """Detect service version"""
        try:
            # Try to connect and get banner
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(target, port),
                timeout=3
            )
            
            # Send probe based on common services
            if port in [21, 22, 25, 80, 443, 3306, 5432, 6379, 27017]:
                writer.write(b'\n')
                await writer.drain()
            
            # Read response
            banner = await asyncio.wait_for(reader.read(1024), timeout=2)
            writer.close()
            await writer.wait_closed()
            
            if banner:
                return {
                    'banner': banner.decode('utf-8', errors='ignore').strip(),
                    'detected': True
                }
        except:
            pass
        
        return None
    
    def _identify_vulnerable_services(self, open_ports: Dict) -> List[Dict]:
        """Identify potentially vulnerable services"""
        vulnerable = []
        
        vulnerability_patterns = {
            'ftp': {
                'ports': [21],
                'risk': 'HIGH',
                'vulnerabilities': ['Anonymous login', 'Weak authentication', 'Brute force']
            },
            'telnet': {
                'ports': [23],
                'risk': 'CRITICAL',
                'vulnerabilities': ['Plaintext credentials', 'No encryption']
            },
            'ssh': {
                'ports': [22],
                'risk': 'MEDIUM',
                'vulnerabilities': ['Weak ciphers', 'Protocol version 1', 'Brute force']
            },
            'smtp': {
                'ports': [25, 587],
                'risk': 'MEDIUM',
                'vulnerabilities': ['Open relay', 'User enumeration']
            },
            'rdp': {
                'ports': [3389],
                'risk': 'HIGH',
                'vulnerabilities': ['BlueKeep', 'Brute force', 'Credential theft']
            },
            'vnc': {
                'ports': [5900, 5901],
                'risk': 'HIGH',
                'vulnerabilities': ['No authentication', 'Weak password', 'Session hijacking']
            },
            'redis': {
                'ports': [6379],
                'risk': 'CRITICAL',
                'vulnerabilities': ['Unauthenticated access', 'RCE via Lua sandbox']
            },
            'mongodb': {
                'ports': [27017],
                'risk': 'HIGH',
                'vulnerabilities': ['No authentication', 'Data exposure']
            },
            'elasticsearch': {
                'ports': [9200, 9300],
                'risk': 'HIGH',
                'vulnerabilities': ['Unauthenticated access', 'RCE']
            },
            'memcached': {
                'ports': [11211],
                'risk': 'HIGH',
                'vulnerabilities': ['Amplification attacks', 'Data leakage']
            }
        }
        
        for port_str, info in open_ports.items():
            port = int(port_str)
            service = info.get('service', '').lower()
            
            for vuln_service, pattern in vulnerability_patterns.items():
                if port in pattern['ports'] or vuln_service in service:
                    vulnerable.append({
                        'port': port,
                        'service': service,
                        'risk_level': pattern['risk'],
                        'vulnerabilities': pattern['vulnerabilities'],
                        'details': info
                    })
                    break
        
        return vulnerable
    
    async def service_detection(self, target: str) -> Dict:
        """Advanced service detection"""
        self.logger.log('INFO', f"Detecting services on {target}", "SERVICE")
        
        services = {}
        
        # HTTP/HTTPS services
        http_services = await self._detect_http_services(target)
        if http_services:
            services['web'] = http_services
        
        # Database services
        db_services = await self._detect_database_services(target)
        if db_services:
            services['databases'] = db_services
        
        # Mail services
        mail_services = await self._detect_mail_services(target)
        if mail_services:
            services['mail'] = mail_services
        
        # File services
        file_services = await self._detect_file_services(target)
        if file_services:
            services['file'] = file_services
        
        return services
    
    async def _detect_http_services(self, target: str) -> Dict:
        """Detect HTTP/HTTPS services"""
        results = {}
        
        for scheme in ['https', 'http']:
            for port in [443, 80, 8080, 8443, 3000, 8000]:
                url = f"{scheme}://{target}:{port}"
                
                try:
                    async with aiohttp.ClientSession() as session:
                        async with session.get(url, timeout=5, ssl=False) as response:
                            results[f"{scheme}_{port}"] = {
                                'url': url,
                                'status': response.status,
                                'headers': dict(response.headers),
                                'server': response.headers.get('Server', 'Unknown'),
                                'title': await self._extract_page_title(await response.text()),
                                'secure': scheme == 'https'
                            }
                except:
                    continue
        
        return results
    
    async def _extract_page_title(self, html: str) -> str:
        """Extract page title from HTML"""
        try:
            soup = BeautifulSoup(html, 'html.parser')
            title = soup.title
            return title.string.strip() if title else 'No title'
        except:
            return 'Error extracting title'
    
    async def _detect_database_services(self, target: str) -> Dict:
        """Detect database services"""
        results = {}
        
        # Common database ports and their detection methods
        db_ports = {
            3306: 'mysql',
            5432: 'postgresql',
            27017: 'mongodb',
            6379: 'redis',
            9200: 'elasticsearch',
            11211: 'memcached',
            1521: 'oracle',
            1433: 'mssql'
        }
        
        for port, db_type in db_ports.items():
            if NetworkUtils.check_port(target, port):
                results[db_type] = {
                    'port': port,
                    'detected': True,
                    'check': 'Port open'
                }
        
        return results
    
    async def _detect_mail_services(self, target: str) -> Dict:
        """Detect mail services"""
        results = {}
        
        mail_ports = {
            25: 'smtp',
            587: 'smtps',
            465: 'smtp_ssl',
            110: 'pop3',
            995: 'pop3s',
            143: 'imap',
            993: 'imaps'
        }
        
        for port, service in mail_ports.items():
            if NetworkUtils.check_port(target, port):
                results[service] = {
                    'port': port,
                    'detected': True
                }
        
        return results
    
    async def _detect_file_services(self, target: str) -> Dict:
        """Detect file services"""
        results = {}
        
        file_ports = {
            21: 'ftp',
            22: 'sftp',
            2049: 'nfs',
            139: 'netbios',
            445: 'smb'
        }
        
        for port, service in file_ports.items():
            if NetworkUtils.check_port(target, port):
                results[service] = {
                    'port': port,
                    'detected': True
                }
        
        return results
    
    async def technology_fingerprinting(self, target: str) -> Dict:
        """Fingerprint technologies used by target"""
        self.logger.log('INFO', f"Fingerprinting technologies on {target}", "TECH")
        
        technologies = {}
        
        try:
            # Use builtwith
            for scheme in ['https', 'http']:
                try:
                    url = f"{scheme}://{target}"
                    tech_data = builtwith.parse(url)
                    
                    if tech_data:
                        for category, items in tech_data.items():
                            if items:
                                technologies[category] = items
                        break
                except:
                    continue
            
            # Additional web technology detection
            web_tech = await self._detect_web_technologies(target)
            if web_tech:
                technologies['web_technologies'] = web_tech
            
            # Detect CMS
            cms = await self._detect_cms(target)
            if cms:
                technologies['cms'] = cms
            
            # Detect frameworks
            frameworks = await self._detect_frameworks(target)
            if frameworks:
                technologies['frameworks'] = frameworks
            
            # Detect security headers
            security = await self._analyze_security_headers(target)
            if security:
                technologies['security'] = security
            
        except Exception as e:
            self.logger.log('ERROR', f"Technology fingerprinting failed: {e}")
        
        return technologies if technologies else {'message': 'No technologies detected'}
    
    async def _detect_web_technologies(self, target: str) -> Dict:
        """Detect specific web technologies"""
        tech = {}
        
        # Check common paths for technology signatures
        checks = [
            ('/wp-admin/', 'wordpress'),
            ('/wp-content/', 'wordpress'),
            ('/wp-includes/', 'wordpress'),
            ('/administrator/', 'joomla'),
            ('/media/system/', 'joomla'),
            ('/user/login', 'drupal'),
            ('/sites/default/', 'drupal'),
            ('/misc/drupal.js', 'drupal'),
            ('/static/admin/', 'django'),
            ('/admin/login/', 'django'),
            ('/node_modules/', 'nodejs'),
            ('/vendor/', 'php_composer'),
            ('/package.json', 'nodejs'),
            ('/composer.json', 'php_composer'),
            ('/.git/', 'git'),
            ('/.svn/', 'svn'),
            ('/.env', 'environment_file'),
            ('/robots.txt', 'robots'),
            ('/sitemap.xml', 'sitemap')
        ]
        
        async with aiohttp.ClientSession() as session:
            for path, technology in checks:
                url = f"https://{target}{path}"
                try:
                    async with session.get(url, timeout=3, ssl=False) as response:
                        if response.status in [200, 403, 401]:
                            tech[technology] = {
                                'path': path,
                                'status': response.status,
                                'detected': True
                            }
                except:
                    continue
        
        return tech
    
    async def _detect_cms(self, target: str) -> List[str]:
        """Detect CMS systems"""
        cms_list = []
        
        # WordPress detection
        wp_urls = ['/wp-login.php', '/wp-admin/', '/xmlrpc.php']
        async with aiohttp.ClientSession() as session:
            for url in wp_urls:
                try:
                    full_url = f"https://{target}{url}"
                    async with session.get(full_url, timeout=3, ssl=False) as response:
                        if response.status in [200, 403, 500]:
                            if 'wordpress' in response.headers.get('X-Powered-By', '').lower():
                                cms_list.append('WordPress')
                                break
                            if 'wp' in (await response.text()).lower():
                                cms_list.append('WordPress')
                                break
                except:
                    continue
        
        return cms_list
    
    async def _detect_frameworks(self, target: str) -> List[str]:
        """Detect web frameworks"""
        frameworks = []
        
        # Common framework signatures
        signatures = {
            'Django': ['csrfmiddlewaretoken', 'django'],
            'Laravel': ['_token', 'laravel'],
            'Ruby on Rails': ['csrf-token', 'rails'],
            'Express.js': ['express', 'x-powered-by: express'],
            'Spring': ['spring', 'jsessionid'],
            'Angular': ['ng-', 'angular'],
            'React': ['react', '__react'],
            'Vue.js': ['vue', '__vue']
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"https://{target}"
                async with session.get(url, timeout=5, ssl=False) as response:
                    text = await response.text()
                    headers = str(response.headers).lower()
                    
                    for framework, patterns in signatures.items():
                        for pattern in patterns:
                            if pattern.lower() in text.lower() or pattern.lower() in headers:
                                frameworks.append(framework)
                                break
        except:
            pass
        
        return list(set(frameworks))
    
    async def _analyze_security_headers(self, target: str) -> Dict:
        """Analyze security headers"""
        security = {
            'present': [],
            'missing': [],
            'recommendations': []
        }
        
        required_headers = [
            'Strict-Transport-Security',
            'X-Content-Type-Options',
            'X-Frame-Options',
            'X-XSS-Protection',
            'Content-Security-Policy',
            'Referrer-Policy'
        ]
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"https://{target}"
                async with session.get(url, timeout=5, ssl=False) as response:
                    headers = response.headers
                    
                    for header in required_headers:
                        if header in headers:
                            security['present'].append(header)
                        else:
                            security['missing'].append(header)
                    
                    # Analyze HSTS
                    if 'Strict-Transport-Security' in headers:
                        hsts = headers['Strict-Transport-Security']
                        if 'max-age=31536000' in hsts and 'includeSubDomains' in hsts:
                            security['hsts_status'] = 'Strong'
                        else:
                            security['hsts_status'] = 'Weak'
                            security['recommendations'].append('Strengthen HSTS policy')
                    
                    # Check for server disclosure
                    if 'Server' in headers:
                        security['server_disclosure'] = headers['Server']
                        security['recommendations'].append('Hide Server header')
        
        except:
            pass
        
        return security
    
    async def web_crawling(self, target: str) -> Dict:
        """Web crawling and content analysis"""
        self.logger.log('INFO', f"Crawling website: {target}", "CRAWLER")
        
        results = {
            'pages': [],
            'links': [],
            'forms': [],
            'files': [],
            'emails': [],
            'phones': []
        }
        
        try:
            # Start with homepage
            start_url = f"https://{target}"
            crawled = set()
            to_crawl = [start_url]
            
            async with aiohttp.ClientSession() as session:
                while to_crawl and len(crawled) < 50:  # Limit to 50 pages
                    url = to_crawl.pop(0)
                    
                    if url in crawled:
                        continue
                    
                    try:
                        async with session.get(url, timeout=10, ssl=False) as response:
                            if response.status == 200:
                                html = await response.text()
                                
                                # Parse page
                                page_info = await self._analyze_page(url, html)
                                results['pages'].append(page_info)
                                
                                # Extract links
                                new_links = await self._extract_links(html, target)
                                for link in new_links:
                                    if link not in crawled and link not in to_crawl:
                                        if target in link:  # Stay on target domain
                                            to_crawl.append(link)
                                        results['links'].append(link)
                                
                                # Extract forms
                                forms = await self._extract_forms(html)
                                results['forms'].extend(forms)
                                
                                # Extract files
                                files = await self._extract_files(html)
                                results['files'].extend(files)
                                
                                # Extract emails
                                emails = self._extract_emails(html)
                                results['emails'].extend(emails)
                                
                                # Extract phone numbers
                                phones = self._extract_phone_numbers(html)
                                results['phones'].extend(phones)
                                
                                crawled.add(url)
                                
                                # Rate limiting
                                await asyncio.sleep(0.5)
                    
                    except:
                        continue
        
        except Exception as e:
            self.logger.log('ERROR', f"Web crawling failed: {e}")
        
        # Remove duplicates
        for key in results:
            if isinstance(results[key], list):
                results[key] = list(set(results[key]))
        
        return results
    
    async def _analyze_page(self, url: str, html: str) -> Dict:
        """Analyze single page"""
        soup = BeautifulSoup(html, 'html.parser')
        
        # Extract metadata
        metadata = {}
        for meta in soup.find_all('meta'):
            if meta.get('name'):
                metadata[meta['name']] = meta.get('content', '')
            elif meta.get('property'):
                metadata[meta['property']] = meta.get('content', '')
        
        # Extract scripts and styles
        scripts = [script.get('src', '') for script in soup.find_all('script') if script.get('src')]
        styles = [link.get('href', '') for link in soup.find_all('link', rel='stylesheet') if link.get('href')]
        
        # Count elements
        element_counts = {
            'links': len(soup.find_all('a')),
            'images': len(soup.find_all('img')),
            'forms': len(soup.find_all('form')),
            'tables': len(soup.find_all('table')),
            'headings': len(soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6']))
        }
        
        return {
            'url': url,
            'title': soup.title.string if soup.title else '',
            'metadata': metadata,
            'scripts': scripts[:10],  # Limit
            'styles': styles[:10],
            'element_counts': element_counts,
            'word_count': len(html.split())
        }
    
    async def _extract_links(self, html: str, base_domain: str) -> List[str]:
        """Extract links from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        links = []
        
        for link in soup.find_all('a', href=True):
            href = link['href']
            
            # Convert relative URLs to absolute
            if href.startswith('/'):
                href = f"https://{base_domain}{href}"
            elif href.startswith('http'):
                pass  # Already absolute
            else:
                href = f"https://{base_domain}/{href}"
            
            # Filter and normalize
            if base_domain in href and href not in links:
                links.append(href)
        
        return links
    
    async def _extract_forms(self, html: str) -> List[Dict]:
        """Extract forms from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        forms = []
        
        for form in soup.find_all('form'):
            form_data = {
                'action': form.get('action', ''),
                'method': form.get('method', 'get').upper(),
                'inputs': []
            }
            
            for input_tag in form.find_all(['input', 'textarea', 'select']):
                input_info = {
                    'type': input_tag.get('type', 'text'),
                    'name': input_tag.get('name', ''),
                    'id': input_tag.get('id', ''),
                    'class': input_tag.get('class', []),
                    'placeholder': input_tag.get('placeholder', ''),
                    'required': input_tag.get('required') is not None
                }
                form_data['inputs'].append(input_info)
            
            forms.append(form_data)
        
        return forms
    
    async def _extract_files(self, html: str) -> List[str]:
        """Extract file links from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        files = []
        
        file_extensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
                          '.txt', '.csv', '.json', '.xml', '.zip', '.rar', '.7z',
                          '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.mp4',
                          '.mp3', '.wav', '.avi', '.mov']
        
        for link in soup.find_all(['a', 'link', 'script', 'img'], href=True):
            href = link['href']
            if any(href.lower().endswith(ext) for ext in file_extensions):
                files.append(href)
        
        for link in soup.find_all('img', src=True):
            src = link['src']
            if any(src.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg']):
                files.append(src)
        
        return list(set(files))
    
    def _extract_emails(self, html: str) -> List[str]:
        """Extract email addresses from text"""
        pattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
        emails = re.findall(pattern, html)
        return list(set(emails))
    
    def _extract_phone_numbers(self, html: str) -> List[str]:
        """Extract phone numbers from text"""
        patterns = [
            r'\+?1?\s*\(?[0-9]{3}\)?[\s.-]?[0-9]{3}[\s.-]?[0-9]{4}',
            r'\(\d{3}\)\s*\d{3}[\s.-]\d{4}',
            r'\d{3}[\s.-]\d{3}[\s.-]\d{4}'
        ]
        
        phones = []
        for pattern in patterns:
            phones.extend(re.findall(pattern, html))
        
        return list(set(phones))
    
    async def vulnerability_scan(self, target: str) -> Dict:
        """Basic vulnerability scanning"""
        self.logger.log('INFO', f"Scanning for vulnerabilities: {target}", "VULNSCAN")
        
        vulnerabilities = {
            'web': [],
            'network': [],
            'configuration': []
        }
        
        # Web vulnerabilities
        web_vulns = await self._scan_web_vulnerabilities(target)
        vulnerabilities['web'] = web_vulns
        
        # Network vulnerabilities
        net_vulns = await self._scan_network_vulnerabilities(target)
        vulnerabilities['network'] = net_vulns
        
        # Configuration issues
        config_vulns = await self._scan_configuration_issues(target)
        vulnerabilities['configuration'] = config_vulns
        
        # Calculate risk score
        total_vulns = len(web_vulns) + len(net_vulns) + len(config_vulns)
        risk_score = min(total_vulns * 10, 100)
        
        vulnerabilities['summary'] = {
            'total_vulnerabilities': total_vulns,
            'risk_score': risk_score,
            'risk_level': 'CRITICAL' if risk_score >= 80 else 'HIGH' if risk_score >= 60 else 'MEDIUM' if risk_score >= 40 else 'LOW'
        }
        
        return vulnerabilities
    
    async def _scan_web_vulnerabilities(self, target: str) -> List[Dict]:
        """Scan for web vulnerabilities"""
        vulns = []
        
        # Common vulnerability checks
        checks = [
            ('SQL Injection', '/?id=1\'', 'sql', 'HIGH'),
            ('XSS', '/?q=<script>alert(1)</script>', 'xss', 'MEDIUM'),
            ('Path Traversal', '/../../../../etc/passwd', 'lfi', 'HIGH'),
            ('Command Injection', '/?cmd=id', 'rce', 'CRITICAL'),
            ('SSRF', '/?url=http://169.254.169.254', 'ssrf', 'HIGH'),
            ('Open Redirect', '/?redirect=http://evil.com', 'redirect', 'LOW'),
            ('File Upload', '/upload.php', 'upload', 'HIGH'),
            ('Login Bypass', '/admin/login.php', 'auth', 'CRITICAL')
        ]
        
        async with aiohttp.ClientSession() as session:
            for vuln_name, payload, vuln_type, risk in checks:
                try:
                    url = f"https://{target}{payload}"
                    async with session.get(url, timeout=5, ssl=False) as response:
                        text = await response.text()
                        
                        # Basic detection patterns
                        detected = False
                        if vuln_type == 'sql' and any(err in text.lower() for err in ['sql', 'syntax', 'mysql', 'postgres']):
                            detected = True
                        elif vuln_type == 'xss' and '<script>' in text:
                            detected = True
                        elif vuln_type == 'lfi' and 'root:' in text:
                            detected = True
                        
                        if detected:
                            vulns.append({
                                'name': vuln_name,
                                'type': vuln_type,
                                'risk': risk,
                                'url': url,
                                'status': response.status
                            })
                
                except:
                    continue
        
        return vulns
    
    async def _scan_network_vulnerabilities(self, target: str) -> List[Dict]:
        """Scan for network vulnerabilities"""
        vulns = []
        
        # Check for outdated services
        outdated_services = {
            21: 'FTP (consider SFTP)',
            23: 'Telnet (use SSH)',
            80: 'HTTP (use HTTPS)',
            110: 'POP3 (use POP3S)',
            143: 'IMAP (use IMAPS)'
        }
        
        for port, issue in outdated_services.items():
            if NetworkUtils.check_port(target, port):
                vulns.append({
                    'name': f'Outdated Service: {issue}',
                    'type': 'outdated',
                    'risk': 'MEDIUM',
                    'port': port,
                    'description': f'Service on port {port} uses insecure protocol'
                })
        
        # Check SSL/TLS issues
        ssl_info = NetworkUtils.get_ssl_certificate(target)
        if ssl_info:
            if not ssl_info.get('valid', True):
                vulns.append({
                    'name': 'Invalid SSL Certificate',
                    'type': 'ssl',
                    'risk': 'HIGH',
                    'description': 'SSL certificate is invalid or expired'
                })
            
            if ssl_info.get('days_remaining', 0) < 30:
                vulns.append({
                    'name': 'SSL Certificate Expiring Soon',
                    'type': 'ssl',
                    'risk': 'MEDIUM',
                    'description': f'Certificate expires in {ssl_info.get("days_remaining")} days'
                })
        
        return vulns
    
    async def _scan_configuration_issues(self, target: str) -> List[Dict]:
        """Scan for configuration issues"""
        issues = []
        
        # Check for common misconfigurations
        common_paths = [
            '/.git/HEAD',
            '/.env',
            '/config.json',
            '/database.yml',
            '/wp-config.php',
            '/phpinfo.php',
            '/test.php',
            '/admin/',
            '/backup/',
            '/logs/',
            '/debug/'
        ]
        
        async with aiohttp.ClientSession() as session:
            for path in common_paths:
                try:
                    url = f"https://{target}{path}"
                    async with session.get(url, timeout=3, ssl=False) as response:
                        if response.status in [200, 403, 401]:
                            risk = 'HIGH' if response.status == 200 else 'MEDIUM'
                            issues.append({
                                'name': f'Sensitive Path Exposure: {path}',
                                'type': 'misconfiguration',
                                'risk': risk,
                                'path': path,
                                'status': response.status,
                                'description': f'Sensitive path accessible: {path}'
                            })
                except:
                    continue
        
        return issues
    
    async def generate_intelligence_report(self, recon_data: Dict) -> Dict:
        """Generate intelligence report from reconnaissance data"""
        report = {
            'threat_assessment': self._assess_threat_level(recon_data),
            'attack_surface': self._calculate_attack_surface(recon_data),
            'vulnerability_summary': self._summarize_vulnerabilities(recon_data),
            'recommendations': self._generate_recommendations(recon_data),
            'confidence_score': self._calculate_confidence_score(recon_data)
        }
        
        return report
    
    def _assess_threat_level(self, recon_data: Dict) -> Dict:
        """Assess overall threat level"""
        score = 0
        factors = []
        
        # Subdomains factor
        subs = recon_data.get('subdomain_enumeration', {}).get('data', {})
        sub_count = subs.get('total_found', 0)
        if sub_count > 50:
            score += 3
            factors.append('Large number of subdomains (potential attack surface)')
        elif sub_count > 20:
            score += 2
            factors.append('Multiple subdomains identified')
        
        # Open ports factor
        ports = recon_data.get('port_scanning', {}).get('data', {})
        port_count = ports.get('total_open', 0)
        if port_count > 20:
            score += 3
            factors.append(f'{port_count} open ports (increased exposure)')
        elif port_count > 10:
            score += 2
            factors.append(f'{port_count} open ports')
        
        # Vulnerable services factor
        vuln_services = ports.get('vulnerable_services', [])
        if vuln_services:
            score += len(vuln_services) * 2
            factors.append(f'{len(vuln_services)} potentially vulnerable services')
        
        # Web vulnerabilities factor
        vuln_scan = recon_data.get('vulnerability_scan', {}).get('data', {})
        web_vulns = vuln_scan.get('web', [])
        if web_vulns:
            score += len(web_vulns) * 3
            factors.append(f'{len(web_vulns)} web vulnerabilities detected')
        
        # Determine threat level
        if score >= 15:
            level = 'CRITICAL'
            color = Fore.RED
        elif score >= 10:
            level = 'HIGH'
            color = Fore.YELLOW
        elif score >= 5:
            level = 'MEDIUM'
            color = Fore.BLUE
        else:
            level = 'LOW'
            color = Fore.GREEN
        
        return {
            'level': level,
            'score': score,
            'factors': factors,
            'color': color
        }
    
    def _calculate_attack_surface(self, recon_data: Dict) -> Dict:
        """Calculate attack surface"""
        surface = {
            'network': 0,
            'web': 0,
            'services': 0,
            'total': 0
        }
        
        # Network surface (ports)
        ports = recon_data.get('port_scanning', {}).get('data', {})
        surface['network'] = ports.get('total_open', 0)
        
        # Web surface (subdomains + pages)
        subs = recon_data.get('subdomain_enumeration', {}).get('data', {})
        surface['web'] = subs.get('total_found', 0)
        
        # Services surface (unique services)
        services = recon_data.get('service_detection', {}).get('data', {})
        surface['services'] = len(services)
        
        # Total
        surface['total'] = surface['network'] + surface['web'] + surface['services']
        
        return surface
    
    def _summarize_vulnerabilities(self, recon_data: Dict) -> Dict:
        """Summarize vulnerabilities"""
        summary = {
            'critical': 0,
            'high': 0,
            'medium': 0,
            'low': 0,
            'total': 0
        }
        
        # Count from vulnerability scan
        vuln_scan = recon_data.get('vulnerability_scan', {}).get('data', {})
        
        for category in ['web', 'network', 'configuration']:
            vulns = vuln_scan.get(category, [])
            for vuln in vulns:
                risk = vuln.get('risk', 'low').upper()
                if risk in summary:
                    summary[risk] += 1
        
        # Count from port scanning
        ports = recon_data.get('port_scanning', {}).get('data', {})
        vuln_services = ports.get('vulnerable_services', [])
        for service in vuln_services:
            risk = service.get('risk_level', 'medium').upper()
            if risk in summary:
                summary[risk] += 1
        
        summary['total'] = sum(summary.values())
        
        return summary
    
    def _generate_recommendations(self, recon_data: Dict) -> List[Dict]:
        """Generate security recommendations"""
        recommendations = []
        
        # Based on open ports
        ports = recon_data.get('port_scanning', {}).get('data', {})
        open_ports = ports.get('open_ports', {})
        
        for port_str, info in open_ports.items():
            port = int(port_str)
            service = info.get('service', '')
            
            # Close unnecessary ports
            if port in [21, 23, 69, 79, 111, 135, 137, 138, 139, 445]:
                recommendations.append({
                    'priority': 'HIGH',
                    'category': 'network',
                    'recommendation': f'Close port {port} ({service}) as it uses insecure protocols',
                    'action': 'Firewall configuration'
                })
        
        # Based on vulnerabilities
        vuln_scan = recon_data.get('vulnerability_scan', {}).get('data', {})
        web_vulns = vuln_scan.get('web', [])
        
        for vuln in web_vulns:
            recommendations.append({
                'priority': vuln.get('risk', 'MEDIUM'),
                'category': 'web',
                'recommendation': f'Fix {vuln.get("name")} vulnerability',
                'action': 'Code review and patching'
            })
        
        # Based on SSL/TLS
        tech = recon_data.get('technology_fingerprinting', {}).get('data', {})
        security = tech.get('security', {})
        
        if 'missing' in security and security['missing']:
            for header in security['missing'][:3]:  # Limit to top 3
                recommendations.append({
                    'priority': 'MEDIUM',
                    'category': 'web',
                    'recommendation': f'Add security header: {header}',
                    'action': 'Server configuration'
                })
        
        # Limit to top 10 recommendations
        return recommendations[:10]
    
    def _calculate_confidence_score(self, recon_data: Dict) -> float:
        """Calculate confidence score for findings"""
        score = 0.5  # Base score
        
        # Add points for comprehensive data
        modules = ['subdomain_enumeration', 'port_scanning', 'technology_fingerprinting', 'vulnerability_scan']
        for module in modules:
            if module in recon_data and 'error' not in recon_data[module].get('data', {}):
                score += 0.1
        
        # Add points for detailed findings
        ports = recon_data.get('port_scanning', {}).get('data', {})
        if ports.get('total_open', 0) > 0:
            score += 0.1
        
        subs = recon_data.get('subdomain_enumeration', {}).get('data', {})
        if subs.get('total_found', 0) > 0:
            score += 0.1
        
        # Cap at 0.95
        return min(score, 0.95)

# =============================================================================
# EXPLOITATION MODULE - BASIC
# =============================================================================

class ExploitationModule:
    """Basic exploitation module (for educational purposes only)"""
    
    def __init__(self, logger: Logger):
        self.logger = logger
        self.payloads = self._load_payloads()
    
    def _load_payloads(self) -> Dict:
        """Load exploitation payloads"""
        return {
            'sql_injection': [
                "' OR '1'='1",
                "' OR '1'='1' --",
                "' OR '1'='1' #",
                "' UNION SELECT NULL--",
                "' UNION SELECT username, password FROM users--"
            ],
            'xss': [
                "<script>alert('XSS')</script>",
                "<img src=x onerror=alert('XSS')>",
                "<svg onload=alert('XSS')>",
                "javascript:alert('XSS')",
                "\" onmouseover=\"alert('XSS')\""
            ],
            'command_injection': [
                "; ls",
                "| ls",
                "&& ls",
                "|| ls",
                "`ls`"
            ],
            'path_traversal': [
                "../../../etc/passwd",
                "..\\..\\..\\windows\\win.ini",
                "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
            ]
        }
    
    async def test_vulnerabilities(self, target: str, recon_data: Dict) -> Dict:
        """Test for vulnerabilities (educational purposes only)"""
        self.logger.log('INFO', f"Testing vulnerabilities on {target}", "EXPLOIT")
        
        results = {
            'tested': [],
            'confirmed': [],
            'false_positives': []
        }
        
        # Only test on authorized targets
        if not self._is_authorized(target):
            self.logger.log('WARNING', f"Not authorized to test {target}", "EXPLOIT")
            return results
        
        # Get potential vulnerabilities from recon
        vuln_scan = recon_data.get('recon', {}).get('vulnerability_scan', {}).get('data', {})
        web_vulns = vuln_scan.get('web', [])
        
        # Test each vulnerability
        for vuln in web_vulns[:5]:  # Limit testing
            vuln_type = vuln.get('type', '')
            url = vuln.get('url', '')
            
            if vuln_type in self.payloads and url:
                test_result = await self._test_vulnerability(url, vuln_type)
                results['tested'].append({
                    'type': vuln_type,
                    'url': url,
                    'result': test_result
                })
                
                if test_result.get('confirmed'):
                    results['confirmed'].append({
                        'type': vuln_type,
                        'url': url,
                        'details': test_result
                    })
                else:
                    results['false_positives'].append({
                        'type': vuln_type,
                        'url': url
                    })
        
        return results
    
    async def _test_vulnerability(self, url: str, vuln_type: str) -> Dict:
        """Test specific vulnerability"""
        payloads = self.payloads.get(vuln_type, [])
        
        for payload in payloads[:2]:  # Test first 2 payloads only
            try:
                test_url = f"{url}{payload}" if '?' in url else f"{url}?test={payload}"
                
                async with aiohttp.ClientSession() as session:
                    async with session.get(test_url, timeout=5, ssl=False) as response:
                        text = await response.text()
                        
                        # Basic detection logic
                        detected = False
                        if vuln_type == 'sql_injection' and any(err in text.lower() for err in ['sql', 'syntax', 'mysql']):
                            detected = True
                        elif vuln_type == 'xss' and payload in text:
                            detected = True
                        
                        if detected:
                            return {
                                'payload': payload,
                                'confirmed': True,
                                'status': response.status,
                                'evidence': text[:200]
                            }
            
            except:
                continue
        
        return {'confirmed': False}
    
    def _is_authorized(self, target: str) -> bool:
        """Check if target is authorized for testing"""
        # In a real tool, this would check against authorization lists
        # For now, return False for safety
        return False

# =============================================================================
# REPORTING MODULE - ADVANCED
# =============================================================================

class ReportingModule:
    """Advanced reporting module"""
    
    def __init__(self, logger: Logger):
        self.logger = logger
        self.reports_dir = Path("reports")
        self.reports_dir.mkdir(exist_ok=True)
    
    async def generate_report(self, data: Dict, format: str = "all") -> Dict[str, Path]:
        """Generate reports in multiple formats"""
        reports = {}
        
        if format in ["html", "all"]:
            reports['html'] = await self._generate_html_report(data)
        
        if format in ["json", "all"]:
            reports['json'] = self._generate_json_report(data)
        
        if format in ["txt", "all"]:
            reports['txt'] = self._generate_text_report(data)
        
        if format in ["md", "all"]:
            reports['md'] = self._generate_markdown_report(data)
        
        return reports
    
    async def _generate_html_report(self, data: Dict) -> Path:
        """Generate HTML report"""
        target = data.get('target', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"cyberghost_{target}_{timestamp}.html"
        filepath = self.reports_dir / filename
        
        # HTML template
        html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberGhost Report - {target}</title>
    <style>
        body {{
            font-family: 'Consolas', 'Monaco', monospace;
            background: #0a0a0a;
            color: #00ff41;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
        }}
        
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(0, 20, 0, 0.3);
            border: 1px solid #00ff41;
            padding: 30px;
            box-shadow: 0 0 20px rgba(0, 255, 65, 0.3);
        }}
        
        .header {{
            text-align: center;
            border-bottom: 2px solid #00ff41;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }}
        
        h1, h2, h3 {{
            color: #00ff9d;
            text-transform: uppercase;
            letter-spacing: 2px;
        }}
        
        h1 {{
            font-size: 2.5em;
            text-shadow: 0 0 10px #00ff41;
        }}
        
        .section {{
            margin: 30px 0;
            padding: 20px;
            border: 1px solid rgba(0, 255, 65, 0.3);
            background: rgba(0, 30, 0, 0.2);
        }}
        
        .metrics {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }}
        
        .metric {{
            text-align: center;
            padding: 15px;
            border: 1px solid #00ff41;
            background: rgba(0, 255, 65, 0.1);
        }}
        
        .metric .value {{
            font-size: 2.5em;
            font-weight: bold;
            color: #00ff41;
        }}
        
        .metric .label {{
            font-size: 0.9em;
            color: #0c0;
            text-transform: uppercase;
        }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }}
        
        th {{
            background: rgba(0, 255, 65, 0.2);
            color: #00ff41;
            padding: 12px;
            text-align: left;
            border: 1px solid #00ff41;
        }}
        
        td {{
            padding: 10px;
            border: 1px solid rgba(0, 255, 65, 0.3);
        }}
        
        tr:hover {{
            background: rgba(0, 255, 65, 0.1);
        }}
        
        .risk-critical {{ color: #ff0000; font-weight: bold; }}
        .risk-high {{ color: #ff3300; }}
        .risk-medium {{ color: #ff9900; }}
        .risk-low {{ color: #00ff41; }}
        .risk-info {{ color: #0099ff; }}
        
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #00ff41;
            color: #0c0;
            font-size: 0.9em;
        }}
        
        .timestamp {{
            font-size: 0.8em;
            color: #0c0;
            text-align: right;
            margin-bottom: 20px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚡ CYBERGHOST OSINT REPORT</h1>
            <div class="timestamp">Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</div>
            <h2>Target: {target}</h2>
            <p>Operator: Leonardo Pereira Pinheiro (CyberGhost)</p>
        </div>
        
        <div class="section">
            <h2>🎯 Executive Summary</h2>
            {self._generate_executive_summary_html(data)}
        </div>
        
        <div class="section">
            <h2>📊 Key Metrics</h2>
            {self._generate_metrics_html(data)}
        </div>
        
        <div class="section">
            <h2>🔍 Findings</h2>
            {self._generate_findings_html(data)}
        </div>
        
        <div class="section">
            <h2>⚠️ Threat Assessment</h2>
            {self._generate_threat_assessment_html(data)}
        </div>
        
        <div class="section">
            <h2>✅ Recommendations</h2>
            {self._generate_recommendations_html(data)}
        </div>
        
        <div class="footer">
            <p>Generated by CYBERGHOST OSINT v5.0 | Shadow Warrior Edition</p>
            <p>FOR AUTHORIZED PENETRATION TESTING ONLY</p>
            <p>© 2024 Leonardo Pereira Pinheiro - All rights reserved</p>
        </div>
    </div>
</body>
</html>
        """
        
        async with aiofiles.open(filepath, 'w', encoding='utf-8') as f:
            await f.write(html)
        
        self.logger.log('SUCCESS', f"HTML report generated: {filepath}", "REPORT")
        return filepath
    
    def _generate_executive_summary_html(self, data: Dict) -> str:
        """Generate executive summary HTML"""
        intel = data.get('intelligence', {})
        threat = intel.get('threat_assessment', {})
        
        html = f"""
        <p>Comprehensive security assessment of <strong>{data.get('target', 'Unknown')}</strong> 
        completed on {datetime.now().strftime('%Y-%m-%d')}.</p>
        
        <p>Threat Level: <span class="risk-{threat.get('level', 'info').lower()}">
        {threat.get('level', 'UNKNOWN')}</span> (Score: {threat.get('score', 0)}/100)</p>
        
        <p>{len(threat.get('factors', []))} risk factors identified.</p>
        """
        
        return html
    
    def _generate_metrics_html(self, data: Dict) -> str:
        """Generate metrics HTML"""
        recon = data.get('recon', {})
        
        # Get metrics from recon data
        subs = recon.get('subdomain_enumeration', {}).get('data', {})
        ports = recon.get('port_scanning', {}).get('data', {})
        vuln = recon.get('vulnerability_scan', {}).get('data', {})
        
        html = '<div class="metrics">'
        
        metrics = [
            ('Subdomains', subs.get('total_found', 0), '#00ff41'),
            ('Open Ports', ports.get('total_open', 0), '#ff9900'),
            ('Vulnerabilities', vuln.get('summary', {}).get('total_vulnerabilities', 0), '#ff3300'),
            ('Technologies', len(recon.get('technology_fingerprinting', {}).get('data', {})), '#0099ff')
        ]
        
        for label, value, color in metrics:
            html += f"""
            <div class="metric">
                <div class="value" style="color: {color};">{value}</div>
                <div class="label">{label}</div>
            </div>
            """
        
        html += '</div>'
        return html
    
    def _generate_findings_html(self, data: Dict) -> str:
        """Generate findings HTML"""
        recon = data.get('recon', {})
        html = ""
        
        # Subdomains
        subs = recon.get('subdomain_enumeration', {}).get('data', {})
        if subs.get('total_found', 0) > 0:
            html += f"""
            <h3>Subdomains Found: {subs['total_found']}</h3>
            <p>Sample subdomains:</p>
            <ul>
            """
            for sub in subs.get('validated', [])[:10]:
                html += f"<li>{sub}</li>"
            html += "</ul>"
        
        # Open Ports
        ports = recon.get('port_scanning', {}).get('data', {})
        if ports.get('open_ports'):
            html += f"""
            <h3>Open Ports: {ports.get('total_open', 0)}</h3>
            <table>
                <tr>
                    <th>Port</th>
                    <th>Service</th>
                    <th>State</th>
                    <th>Details</th>
                </tr>
            """
            for port, info in list(ports.get('open_ports', {}).items())[:10]:
                html += f"""
                <tr>
                    <td>{port}</td>
                    <td>{info.get('service', 'unknown')}</td>
                    <td>{info.get('state', 'unknown')}</td>
                    <td>{info.get('product', '')} {info.get('version', '')}</td>
                </tr>
                """
            html += "</table>"
        
        return html
    
    def _generate_threat_assessment_html(self, data: Dict) -> str:
        """Generate threat assessment HTML"""
        intel = data.get('intelligence', {})
        threat = intel.get('threat_assessment', {})
        vuln_summary = intel.get('vulnerability_summary', {})
        
        html = f"""
        <div class="metric" style="border-color: {threat.get('color', '#00ff41')};">
            <div class="value" style="color: {threat.get('color', '#00ff41')};">{threat.get('level', 'UNKNOWN')}</div>
            <div class="label">Threat Level</div>
        </div>
        
        <h3>Vulnerability Breakdown:</h3>
        <table>
            <tr>
                <th>Severity</th>
                <th>Count</th>
            </tr>
        """
        
        for severity in ['critical', 'high', 'medium', 'low']:
            count = vuln_summary.get(severity, 0)
            if count > 0:
                html += f"""
                <tr>
                    <td class="risk-{severity}">{severity.upper()}</td>
                    <td>{count}</td>
                </tr>
                """
        
        html += f"""
        </table>
        
        <h3>Risk Factors:</h3>
        <ul>
        """
        
        for factor in threat.get('factors', [])[:5]:
            html += f"<li>{factor}</li>"
        
        html += "</ul>"
        
        return html
    
    def _generate_recommendations_html(self, data: Dict) -> str:
        """Generate recommendations HTML"""
        intel = data.get('intelligence', {})
        recommendations = intel.get('recommendations', [])
        
        if not recommendations:
            return "<p>No specific recommendations available.</p>"
        
        html = "<table><tr><th>Priority</th><th>Recommendation</th><th>Category</th><th>Action</th></tr>"
        
        for rec in recommendations[:10]:
            priority = rec.get('priority', 'MEDIUM').lower()
            html += f"""
            <tr>
                <td class="risk-{priority}">{rec.get('priority', 'MEDIUM')}</td>
                <td>{rec.get('recommendation', '')}</td>
                <td>{rec.get('category', 'general')}</td>
                <td>{rec.get('action', 'Review')}</td>
            </tr>
            """
        
        html += "</table>"
        return html
    
    def _generate_json_report(self, data: Dict) -> Path:
        """Generate JSON report"""
        target = data.get('target', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"cyberghost_{target}_{timestamp}.json"
        filepath = self.reports_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, default=str, ensure_ascii=False)
        
        self.logger.log('SUCCESS', f"JSON report generated: {filepath}", "REPORT")
        return filepath
    
    def _generate_text_report(self, data: Dict) -> Path:
        """Generate text report"""
        target = data.get('target', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"cyberghost_{target}_{timestamp}.txt"
        filepath = self.reports_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(self._format_text_report(data))
        
        self.logger.log('SUCCESS', f"Text report generated: {filepath}", "REPORT")
        return filepath
    
    def _format_text_report(self, data: Dict) -> str:
        """Format text report"""
        target = data.get('target', 'Unknown')
        intel = data.get('intelligence', {})
        threat = intel.get('threat_assessment', {})
        
        report = f"""
{'='*80}
                    CYBERGHOST OSINT REPORT
{'='*80}

Target: {target}
Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Operator: Leonardo Pereira Pinheiro (CyberGhost)

{'='*80}
                        EXECUTIVE SUMMARY
{'='*80}

Threat Level: {threat.get('level', 'UNKNOWN')} (Score: {threat.get('score', 0)})
Risk Factors: {len(threat.get('factors', []))}

{'='*80}
                          FINDINGS
{'='*80}
        """
        
        # Add findings from recon data
        recon = data.get('recon', {})
        
        for module_name, module_data in recon.items():
            module_info = module_data.get('data', {})
            if module_info:
                report += f"\n[{module_name.upper()}]\n"
                if isinstance(module_info, dict):
                    for key, value in list(module_info.items())[:5]:
                        if key != 'error':
                            report += f"  {key}: {value}\n"
                report += "\n"
        
        report += f"""
{'='*80}
                     RECOMMENDATIONS
{'='*80}
        """
        
        recommendations = intel.get('recommendations', [])
        for i, rec in enumerate(recommendations[:10], 1):
            report += f"\n{i}. [{rec.get('priority', 'MEDIUM')}] {rec.get('recommendation', '')}"
        
        report += f"""

{'='*80}
Generated by CYBERGHOST OSINT v5.0
For authorized penetration testing only
{'='*80}
        """
        
        return report
    
    def _generate_markdown_report(self, data: Dict) -> Path:
        """Generate markdown report"""
        target = data.get('target', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"cyberghost_{target}_{timestamp}.md"
        filepath = self.reports_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(self._format_markdown_report(data))
        
        self.logger.log('SUCCESS', f"Markdown report generated: {filepath}", "REPORT")
        return filepath
    
    def _format_markdown_report(self, data: Dict) -> str:
        """Format markdown report"""
        target = data.get('target', 'Unknown')
        intel = data.get('intelligence', {})
        threat = intel.get('threat_assessment', {})
        
        report = f"""# CyberGhost OSINT Report

## Target: {target}
**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Operator:** Leonardo Pereira Pinheiro (CyberGhost)

---

## Executive Summary

**Threat Level:** `{threat.get('level', 'UNKNOWN')}`  
**Score:** {threat.get('score', 0)}/100  
**Risk Factors:** {len(threat.get('factors', []))}

---

## Key Findings

### Subdomains
"""
        
        recon = data.get('recon', {})
        subs = recon.get('subdomain_enumeration', {}).get('data', {})
        if subs.get('total_found', 0) > 0:
            report += f"\n**Total:** {subs.get('total_found', 0)}\n"
            for sub in subs.get('validated', [])[:10]:
                report += f"- `{sub}`\n"
        
        report += "\n### Open Ports\n"
        ports = recon.get('port_scanning', {}).get('data', {})
        if ports.get('open_ports'):
            report += f"\n**Total:** {ports.get('total_open', 0)}\n\n"
            report += "| Port | Service | State | Details |\n"
            report += "|------|---------|-------|---------|\n"
            for port, info in list(ports.get('open_ports', {}).items())[:10]:
                report += f"| {port} | {info.get('service', 'unknown')} | {info.get('state', 'unknown')} | {info.get('product', '')} {info.get('version', '')} |\n"
        
        report += "\n---\n\n## Recommendations\n\n"
        
        recommendations = intel.get('recommendations', [])
        for i, rec in enumerate(recommendations[:10], 1):
            priority = rec.get('priority', 'MEDIUM')
            report += f"{i}. **[{priority}]** {rec.get('recommendation', '')}\n"
        
        report += "\n---\n\n*Generated by CyberGhost OSINT v5.0*  \n*For authorized penetration testing only*"
        
        return report

# =============================================================================
# MAIN CYBERGHOST CLASS
# =============================================================================

class CyberGhost:
    """Main CyberGhost OSINT framework"""
    
    def __init__(self, config_path: Optional[str] = None):
        # Load configuration
        self.config = Config.load(config_path)
        
        # Initialize components
        self.logger = Logger("CyberGhost", "INFO")
        self.recon = ReconModule(self.logger, self.config)
        self.exploit = ExploitationModule(self.logger)
        self.reporter = ReportingModule(self.logger)
        
        # Statistics
        self.stats = {
            'targets_scanned': 0,
            'vulnerabilities_found': 0,
            'reports_generated': 0,
            'start_time': datetime.now()
        }
        
        # Display banner
        self.logger.banner()
    
    async def scan(self, target: str) -> Dict:
        """Complete scan of target"""
        self.logger.status(target, "INITIATING", "Starting comprehensive scan")
        self.stats['targets_scanned'] += 1
        
        try:
            # Phase 1: Reconnaissance
            self.logger.status(target, "SCANNING", "Phase 1: Reconnaissance")
            recon_data = await self.recon.full_reconnaissance(target)
            
            # Phase 2: Vulnerability testing (if authorized)
            self.logger.status(target, "ANALYZING", "Phase 2: Vulnerability analysis")
            exploit_data = await self.exploit.test_vulnerabilities(target, recon_data)
            
            # Combine data
            result = {
                'target': target,
                'timestamp': datetime.now().isoformat(),
                'recon': recon_data.get('recon', {}),
                'intelligence': recon_data.get('intelligence', {}),
                'exploitation': exploit_data,
                'metadata': {
                    'scan_id': str(uuid.uuid4()),
                    'duration': (datetime.now() - self.stats['start_time']).total_seconds(),
                    'version': self.config['version']
                }
            }
            
            # Count vulnerabilities
            vuln_count = result['intelligence'].get('vulnerability_summary', {}).get('total', 0)
            self.stats['vulnerabilities_found'] += vuln_count
            
            # Phase 3: Reporting
            self.logger.status(target, "REPORTING", "Phase 3: Report generation")
            reports = await self.reporter.generate_report(result, "all")
            self.stats['reports_generated'] += len(reports)
            
            # Display summary
            self._display_scan_summary(result, reports)
            
            return {
                'success': True,
                'data': result,
                'reports': reports
            }
            
        except Exception as e:
            self.logger.log('ERROR', f"Scan failed: {e}", "MAIN")
            return {
                'success': False,
                'error': str(e),
                'target': target
            }
    
    async def batch_scan(self, targets_file: str, max_concurrent: int = 3) -> Dict:
        """Batch scan multiple targets"""
        try:
            with open(targets_file, 'r') as f:
                targets = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        except Exception as e:
            self.logger.log('ERROR', f"Failed to read targets file: {e}")
            return {}
        
        self.logger.log('INFO', f"Starting batch scan of {len(targets)} targets", "BATCH")
        
        results = {}
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def scan_with_limit(target):
            async with semaphore:
                return target, await self.scan(target)
        
        # Create tasks
        tasks = [scan_with_limit(target) for target in targets]
        
        # Process with progress bar
        with tqdm(total=len(tasks), desc="CyberGhost Batch") as pbar:
            for task in asyncio.as_completed(tasks):
                target, result = await task
                results[target] = result
                pbar.update(1)
                
                if result.get('success'):
                    pbar.set_postfix_str(f"✓ {target}")
                else:
                    pbar.set_postfix_str(f"✗ {target}")
        
        # Generate batch report
        batch_report = self._generate_batch_report(results)
        self.logger.log('SUCCESS', f"Batch scan completed: {len(results)} targets", "BATCH")
        
        return batch_report
    
    def _generate_batch_report(self, results: Dict) -> Dict:
        """Generate batch report"""
        summary = {
            'total_targets': len(results),
            'successful_scans': sum(1 for r in results.values() if r.get('success')),
            'failed_scans': sum(1 for r in results.values() if not r.get('success')),
            'total_vulnerabilities': 0,
            'targets_by_risk': Counter(),
            'completion_time': datetime.now().isoformat()
        }
        
        # Collect vulnerabilities and risk levels
        for target, result in results.items():
            if result.get('success'):
                data = result.get('data', {})
                intel = data.get('intelligence', {})
                
                # Count vulnerabilities
                vuln_summary = intel.get('vulnerability_summary', {})
                summary['total_vulnerabilities'] += vuln_summary.get('total', 0)
                
                # Count by risk level
                threat = intel.get('threat_assessment', {})
                risk_level = threat.get('level', 'UNKNOWN')
                summary['targets_by_risk'][risk_level] += 1
        
        # Save batch report
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"cyberghost_batch_{timestamp}.json"
        filepath = Path("reports") / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump({
                'summary': summary,
                'results': {k: v.get('data', {}) for k, v in results.items() if v.get('success')}
            }, f, indent=2, default=str)
        
        self.logger.log('SUCCESS', f"Batch report saved: {filepath}", "REPORT")
        return summary
    
    def _display_scan_summary(self, data: Dict, reports: Dict[str, Path]):
        """Display scan summary"""
        target = data.get('target', 'Unknown')
        intel = data.get('intelligence', {})
        threat = intel.get('threat_assessment', {})
        
        print(f"\n{Fore.CYAN}{'═'*80}")
        print(f"{Fore.GREEN} CYBERGHOST SCAN SUMMARY")
        print(f"{Fore.CYAN}{'═'*80}{Style.RESET_ALL}")
        
        # Key metrics
        metrics = [
            ["Target", target],
            ["Threat Level", f"{threat.get('level', 'N/A')}"],
            ["Risk Score", f"{threat.get('score', 0)}/100"],
            ["Vulnerabilities", intel.get('vulnerability_summary', {}).get('total', 0)],
            ["Confidence", f"{intel.get('confidence_score', 0)*100:.1f}%"],
            ["Scan Duration", f"{data.get('metadata', {}).get('duration', 0):.1f}s"]
        ]
        
        print(tabulate(metrics, tablefmt="grid"))
        
        # Risk factors
        factors = threat.get('factors', [])
        if factors:
            print(f"\n{Fore.YELLOW}Top Risk Factors:{Style.RESET_ALL}")
            for factor in factors[:3]:
                print(f"  {Fore.CYAN}•{Style.RESET_ALL} {factor}")
        
        # Reports
        print(f"\n{Fore.CYAN}Generated Reports:{Style.RESET_ALL}")
        for fmt, path in reports.items():
            print(f"  {Fore.GREEN}✓{Style.RESET_ALL} {fmt.upper()}: {path}")
        
        # Recommendations
        recommendations = intel.get('recommendations', [])
        if recommendations:
            print(f"\n{Fore.YELLOW}Top Recommendations:{Style.RESET_ALL}")
            for rec in recommendations[:3]:
                priority = rec.get('priority', 'MEDIUM')
                color = Fore.RED if priority == 'CRITICAL' else Fore.YELLOW if priority == 'HIGH' else Fore.BLUE if priority == 'MEDIUM' else Fore.GREEN
                print(f"  {color}• [{priority}]{Style.RESET_ALL} {rec.get('recommendation', '')}")
        
        print(f"\n{Fore.CYAN}{'═'*80}{Style.RESET_ALL}")
    
    async def monitor(self, target: str, interval: int = 3600, duration: int = 86400):
        """Continuous monitoring"""
        self.logger.log('INFO', f"Starting continuous monitoring on {target}", "MONITOR")
        
        observations = []
        start_time = datetime.now()
        
        try:
            while (datetime.now() - start_time).seconds < duration:
                self.logger.status(target, "MONITORING", f"Check #{len(observations) + 1}")
                
                # Perform scan
                result = await self.scan(target)
                
                if result.get('success'):
                    observations.append({
                        'timestamp': datetime.now().isoformat(),
                        'data': result.get('data', {})
                    })
                    
                    # Check for changes
                    if len(observations) > 1:
                        changes = self._detect_changes(
                            observations[-2]['data'],
                            observations[-1]['data']
                        )
                        
                        if changes:
                            self._alert_changes(target, changes)
                
                # Wait for next interval
                await asyncio.sleep(interval)
        
        except KeyboardInterrupt:
            self.logger.log('INFO', "Monitoring interrupted by user", "MONITOR")
        except Exception as e:
            self.logger.log('ERROR', f"Monitoring failed: {e}", "MONITOR")
        
        return observations
    
    def _detect_changes(self, old_data: Dict, new_data: Dict) -> List[Dict]:
        """Detect changes between scans"""
        changes = []
        
        # Compare subdomains
        old_recon = old_data.get('recon', {})
        new_recon = new_data.get('recon', {})
        
        old_subs = set(old_recon.get('subdomain_enumeration', {}).get('data', {}).get('validated', []))
        new_subs = set(new_recon.get('subdomain_enumeration', {}).get('data', {}).get('validated', []))
        
        added = new_subs - old_subs
        removed = old_subs - new_subs
        
        if added:
            changes.append({
                'type': 'SUBDOMAIN_ADDED',
                'count': len(added),
                'examples': list(added)[:3]
            })
        
        if removed:
            changes.append({
                'type': 'SUBDOMAIN_REMOVED',
                'count': len(removed),
                'examples': list(removed)[:3]
            })
        
        # Compare open ports
        old_ports = set(old_recon.get('port_scanning', {}).get('data', {}).get('open_ports', {}).keys())
        new_ports = set(new_recon.get('port_scanning', {}).get('data', {}).get('open_ports', {}).keys())
        
        if old_ports != new_ports:
            changes.append({
                'type': 'PORT_CHANGE',
                'old': list(old_ports),
                'new': list(new_ports)
            })
        
        return changes
    
    def _alert_changes(self, target: str, changes: List[Dict]):
        """Alert about detected changes"""
        alert_msg = f"\n{Fore.RED}{'!'*80}"
        alert_msg += f"\n🔔 CYBERGHOST ALERT: Changes detected on {target}"
        alert_msg += f"\n{'!'*80}{Style.RESET_ALL}\n"
        
        for change in changes:
            alert_msg += f"\n{Fore.YELLOW}• {change['type']}:{Style.RESET_ALL}\n"
            for key, value in change.items():
                if key != 'type':
                    alert_msg += f"  {key}: {value}\n"
        
        print(alert_msg)
        
        # Save alert to file
        alert_file = Path("alerts") / f"alert_{target}_{datetime.now():%Y%m%d_%H%M%S}.txt"
        alert_file.parent.mkdir(exist_ok=True)
        
        with open(alert_file, 'w') as f:
            f.write(alert_msg)

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

def print_usage():
    """Print usage information"""
    print(f"""
{Fore.CYAN}╔══════════════════════════════════════════════════════════════════════════════════╗
║                           CYBERGHOST OSINT v5.0                           ║
║                      Advanced Offensive Security Framework                 ║
╚══════════════════════════════════════════════════════════════════════════════════╝{Style.RESET_ALL}

{Fore.GREEN}Usage:{Style.RESET_ALL}
  python cyberghost.py <command> [options]

{Fore.GREEN}Commands:{Style.RESET_ALL}
  scan <target>          Scan a single target (domain or IP)
  batch <file>           Batch scan targets from file
  monitor <target>       Continuous monitoring
  help                   Show this help message

{Fore.GREEN}Examples:{Style.RESET_ALL}
  python cyberghost.py scan example.com
  python cyberghost.py batch targets.txt
  python cyberghost.py monitor example.com --interval 1800

{Fore.GREEN}Options:{Style.RESET_ALL}
  --config <file>        Configuration file
  --output <formats>     Output formats (html,json,txt,md,all)
  --concurrent <n>       Concurrent scans for batch (default: 3)

{Fore.YELLOW}Developer: Leonardo Pereira Pinheiro | Alias: CyberGhost{Style.RESET_ALL}
{Fore.RED}Warning: Use only for authorized penetration testing!{Style.RESET_ALL}
    """)

async def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="CyberGhost OSINT v5.0 - Advanced Offensive Security Framework",
        add_help=False
    )
    
    parser.add_argument('command', nargs='?', help='Command to execute')
    parser.add_argument('target', nargs='?', help='Target to scan')
    parser.add_argument('--config', help='Configuration file')
    parser.add_argument('--output', default='all', help='Output formats')
    parser.add_argument('--concurrent', type=int, default=3, help='Concurrent scans')
    parser.add_argument('--interval', type=int, default=3600, help='Monitoring interval')
    parser.add_argument('--duration', type=int, default=86400, help='Monitoring duration')
    parser.add_argument('--help', '-h', action='store_true', help='Show help')
    
    # Parse arguments
    args, unknown = parser.parse_known_args()
    
    if args.help or not args.command:
        print_usage()
        return
    
    # Initialize CyberGhost
    cyberghost = CyberGhost(args.config)
    
    try:
        if args.command == 'scan':
            if not args.target:
                print(f"{Fore.RED}[!] Error: Target required for scan command{Style.RESET_ALL}")
                print_usage()
                return
            
            await cyberghost.scan(args.target)
            
        elif args.command == 'batch':
            if not args.target:
                print(f"{Fore.RED}[!] Error: File required for batch command{Style.RESET_ALL}")
                print_usage()
                return
            
            await cyberghost.batch_scan(args.target, args.concurrent)
            
        elif args.command == 'monitor':
            if not args.target:
                print(f"{Fore.RED}[!] Error: Target required for monitor command{Style.RESET_ALL}")
                print_usage()
                return
            
            await cyberghost.monitor(args.target, args.interval, args.duration)
            
        else:
            print(f"{Fore.RED}[!] Unknown command: {args.command}{Style.RESET_ALL}")
            print_usage()
    
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}[!] Operation interrupted by user{Style.RESET_ALL}")
    except Exception as e:
        print(f"\n{Fore.RED}[!] Error: {e}{Style.RESET_ALL}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # Check Python version
    import sys
    if sys.version_info < (3, 8):
        print(f"{Fore.RED}[!] Python 3.8 or higher is required{Style.RESET_ALL}")
        sys.exit(1)
    
    # Run main function
    asyncio.run(main())
