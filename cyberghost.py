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
║                                                                                  ║
║   CYBERGHOST OSINT v5.0 - Plataforma de Inteligência Cibernética                   ║
║   Desenvolvido por: Leonardo Pereira Pinheiro                                      ║
║   Código: Shadow Warrior | Alias: CyberGhost                                       ║
║   Licença: GPL-3.0 | Uso Ético e Legal Requerido                                   ║
║                                                                                  ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"""

import asyncio
import aiohttp
import aiofiles
import sys
import os
import json
import uuid
import secrets
import socket
import dns.resolver
import builtwith
import warnings
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path
from bs4 import BeautifulSoup
from colorama import Fore, Style, init as colorama_init
from tabulate import tabulate
from tqdm.auto import tqdm

# Configurações Iniciais
warnings.filterwarnings('ignore')
colorama_init(autoreset=True)

# =============================================================================
# SISTEMA DE LOGGING E IDENTIDADE
# =============================================================================

class CyberGhostLogger:
    def __init__(self):
        self.session_id = secrets.token_hex(4)
        self.start_time = datetime.now()
        Path("reports").mkdir(exist_ok=True)
        Path("logs").mkdir(exist_ok=True)

    def print_banner(self):
        banner = f"""
{Fore.CYAN}╔══════════════════════════════════════════════════════════════════════════════════╗
║{Fore.GREEN}        CYBERGHOST OSINT v5.0 - Shadow Warrior Edition                            {Fore.CYAN}║
║{Fore.YELLOW}        Operator: Leonardo Pereira Pinheiro | Alias: CyberGhost                   {Fore.CYAN}║
╚══════════════════════════════════════════════════════════════════════════════════╝{Style.RESET_ALL}"""
        print(banner)
        print(f"{Fore.GREEN}[+] Session ID: {self.session_id} | Start: {self.start_time:%H:%M:%S}")

    def log(self, level: str, message: str, module: str = "CORE"):
        icons = {'info': "ℹ️", 'success': "✅", 'error': "❌", 'hack': "⚡"}
        color = {'info': Fore.GREEN, 'success': Fore.CYAN, 'error': Fore.RED}.get(level, Fore.WHITE)
        print(f"{color}[{datetime.now():%H:%M:%S}] {icons.get(level, '•')} [{module}] {message}")

# =============================================================================
# MÓDULO DE RECONHECIMENTO (CORREÇÃO DE CORROTINAS)
# =============================================================================

class GhostRecon:
    def __init__(self, logger: CyberGhostLogger):
        self.logger = logger
        self.ports = [21, 22, 23, 25, 53, 80, 110, 443, 3306, 3389, 8080]

    async def _safe_execute(self, name: str, func, arg):
        """Correção do erro 'coroutine object has no attribute call'"""
        try:
            # Garante que a função seja aguardada corretamente se for assíncrona
            if asyncio.iscoroutinefunction(func):
                data = await func(arg)
            else:
                data = func(arg)
            return {'task': name, 'data': data}
        except Exception as e:
            self.logger.log("error", f"Modulo {name} falhou: {str(e)[:50]}", "RECON")
            return {'task': name, 'data': {'error': str(e)}}

    async def full_reconnaissance(self, target: str) -> Dict:
        self.logger.log("info", f"Iniciando reconhecimento em {target}", "RECON")
        
        # Orquestração de tarefas paralelas
        tasks = [
            self._safe_execute('subdomains', self.enumerate_subdomains, target),
            self._safe_execute('ports', self.port_scanning, target),
            self._safe_execute('tech', self.tech_fingerprint, target)
        ]
        
        results = await asyncio.gather(*tasks)
        return {res['task']: res['data'] for res in results}

    async def enumerate_subdomains(self, domain: str) -> Dict:
        subs = ["www", "mail", "ftp", "dev", "api", "admin"]
        found = []
        for sub in subs:
            try:
                full_url = f"{sub}.{domain}"
                socket.gethostbyname(full_url)
                found.append(full_url)
            except: continue
        return {"total": len(found), "list": found}

    async def port_scanning(self, target: str) -> Dict:
        open_ports = {}
        for port in self.ports:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(0.5)
                if sock.connect_ex((target, port)) == 0:
                    open_ports[port] = "OPEN"
                sock.close()
            except: continue
        return {"total_open": len(open_ports), "ports": open_ports}

    async def tech_fingerprint(self, target: str) -> Dict:
        try:
            return builtwith.parse(f"http://{target}")
        except: return {"status": "indetectável"}

# =============================================================================
# SISTEMA DE RELATÓRIOS E IA
# =============================================================================

class GhostReporter:
    def generate(self, data: Dict):
        target = data.get('target', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        path = Path(f"reports/cyberghost_{target}_{timestamp}.json")
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        return path

# =============================================================================
# ORQUESTRAÇÃO PRINCIPAL
# =============================================================================

class CyberGhostOSINT:
    def __init__(self):
        self.logger = CyberGhostLogger()
        self.recon = GhostRecon(self.logger)
        self.reporter = GhostReporter()

    async def ghost_scan(self, target: str):
        self.logger.print_banner()
        start = datetime.now()
        
        # Reconhecimento Corrigido
        recon_data = await self.recon.full_reconnaissance(target)
        
        # Consolidação de Dados
        full_data = {
            "target": target,
            "operator": "Leonardo Pereira Pinheiro",
            "timestamp": datetime.now().isoformat(),
            "recon_data": recon_data,
            "duration": (datetime.now() - start).total_seconds()
        }

        # Dashboard de Resultados
        print(f"\n{Fore.CYAN}{'═'*60}")
        print(f"{Fore.GREEN} DASHBOARD DE SCAN: {target}")
        print(f"{Fore.CYAN}{'═'*60}")
        
        ports = recon_data.get('ports', {}).get('ports', {})
        print(f" [+] Portas Abertas: {len(ports)}")
        for p in ports:
            print(f"   - Port {p}: OPEN")
            
        report_path = self.reporter.generate(full_data)
        self.logger.log("success", f"Relatório gerado: {report_path}", "REPORT")
        print(f"{Fore.CYAN}{'═'*60}\n")

async def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('target', help='Alvo para o scan (domínio ou IP)')
    args = parser.parse_args()
    
    app = CyberGhostOSINT()
    await app.ghost_scan(args.target)

if __name__ == "__main__":
    asyncio.run(main())
