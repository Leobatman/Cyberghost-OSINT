#!/usr/bin/env python3
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Web Dashboard
# =============================================================================

import os
import json
import datetime
import subprocess
from flask import Flask, render_template, jsonify, request, send_file
from flask_socketio import SocketIO, emit
import threading
import queue
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
socketio = SocketIO(app, cors_allowed_origins="*")

# Configurações
REPORTS_DIR = os.path.expanduser("~/CyberGhost_Reports")
LOG_FILE = os.path.expanduser("~/.cyberghost/logs/cyberghost.log")

# Fila de tarefas
task_queue = queue.Queue()
active_tasks = {}

# Rotas principais
@app.route('/')
def index():
    """Página principal"""
    return render_template('dashboard.html')

@app.route('/api/status')
def api_status():
    """Status da API"""
    return jsonify({
        'status': 'online',
        'version': '7.0.0',
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/stats')
def api_stats():
    """Estatísticas do sistema"""
    stats = {
        'total_scans': get_total_scans(),
        'total_findings': get_total_findings(),
        'active_scans': len(active_tasks),
        'uptime': get_uptime(),
        'disk_usage': get_disk_usage(),
        'memory_usage': get_memory_usage()
    }
    return jsonify(stats)

@app.route('/api/scans')
def api_scans():
    """Listar scans"""
    scans = get_recent_scans()
    return jsonify(scans)

@app.route('/api/scan/<scan_id>')
def api_scan(scan_id):
    """Detalhes de um scan"""
    scan_data = get_scan_details(scan_id)
    if scan_data:
        return jsonify(scan_data)
    return jsonify({'error': 'Scan not found'}), 404

@app.route('/api/scan/<scan_id>/report')
def api_scan_report(scan_id):
    """Download do relatório"""
    report_file = get_report_file(scan_id)
    if report_file and os.path.exists(report_file):
        return send_file(report_file, as_attachment=True)
    return jsonify({'error': 'Report not found'}), 404

@app.route('/api/search')
def api_search():
    """Buscar nos resultados"""
    query = request.args.get('q', '')
    results = search_scans(query)
    return jsonify(results)

@app.route('/api/start_scan', methods=['POST'])
def api_start_scan():
    """Iniciar novo scan"""
    data = request.json
    target = data.get('target')
    scan_type = data.get('type', 'full')
    
    if not target:
        return jsonify({'error': 'Target required'}), 400
    
    task_id = start_scan_task(target, scan_type)
    return jsonify({'task_id': task_id, 'status': 'started'})

@app.route('/api/stop_scan/<task_id>', methods=['POST'])
def api_stop_scan(task_id):
    """Parar scan"""
    if task_id in active_tasks:
        stop_scan_task(task_id)
        return jsonify({'status': 'stopped'})
    return jsonify({'error': 'Task not found'}), 404

@app.route('/api/config')
def api_config():
    """Configurações atuais"""
    config = load_config()
    return jsonify(config)

@app.route('/api/config', methods=['POST'])
def api_update_config():
    """Atualizar configurações"""
    data = request.json
    save_config(data)
    socketio.emit('config_updated', data)
    return jsonify({'status': 'updated'})

@app.route('/api/export')
def api_export():
    """Exportar dados"""
    format = request.args.get('format', 'json')
    scan_id = request.args.get('scan_id')
    
    if not scan_id:
        return jsonify({'error': 'Scan ID required'}), 400
    
    export_file = export_scan_data(scan_id, format)
    if export_file:
        return send_file(export_file, as_attachment=True)
    return jsonify({'error': 'Export failed'}), 500

# WebSocket events
@socketio.on('connect')
def handle_connect():
    """Cliente conectado"""
    emit('connected', {'data': 'Connected to CYBERGHOST server'})

@socketio.on('disconnect')
def handle_disconnect():
    """Cliente desconectado"""
    pass

@socketio.on('subscribe')
def handle_subscribe(data):
    """Inscrever em updates"""
    room = data.get('room', 'global')
    emit('subscribed', {'room': room})

# Funções auxiliares
def get_total_scans():
    """Total de scans realizados"""
    try:
        scans_dir = os.path.join(REPORTS_DIR, 'scans')
        if os.path.exists(scans_dir):
            return len([d for d in os.listdir(scans_dir) if d.startswith('scan_')])
    except:
        pass
    return 0

def get_total_findings():
    """Total de findings"""
    total = 0
    try:
        scans_dir = os.path.join(REPORTS_DIR, 'scans')
        if os.path.exists(scans_dir):
            for scan_dir in os.listdir(scans_dir):
                if scan_dir.startswith('scan_'):
                    modules_dir = os.path.join(scans_dir, scan_dir, 'modules')
                    if os.path.exists(modules_dir):
                        for mod_file in os.listdir(modules_dir):
                            if mod_file.endswith('.json'):
                                try:
                                    with open(os.path.join(modules_dir, mod_file)) as f:
                                        data = json.load(f)
                                        total += len(data)
                                except:
                                    pass
    except:
        pass
    return total

def get_uptime():
    """Tempo de atividade"""
    try:
        with open('/proc/uptime') as f:
            uptime_seconds = float(f.read().split()[0])
            return uptime_seconds
    except:
        return 0

def get_disk_usage():
    """Uso de disco"""
    try:
        stat = os.statvfs(REPORTS_DIR)
        total = stat.f_frsize * stat.f_blocks / (1024**3)
        free = stat.f_frsize * stat.f_bfree / (1024**3)
        used = total - free
        return {
            'total': round(total, 2),
            'used': round(used, 2),
            'free': round(free, 2),
            'percent': round((used / total) * 100, 2) if total > 0 else 0
        }
    except:
        return {}

def get_memory_usage():
    """Uso de memória"""
    try:
        with open('/proc/meminfo') as f:
            meminfo = {}
            for line in f:
                parts = line.split(':')
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = parts[1].strip().split()[0]
                    meminfo[key] = int(value) / 1024
        
        total = meminfo.get('MemTotal', 0)
        free = meminfo.get('MemFree', 0)
        used = total - free
        
        return {
            'total': round(total, 2),
            'used': round(used, 2),
            'free': round(free, 2),
            'percent': round((used / total) * 100, 2) if total > 0 else 0
        }
    except:
        return {}

def get_recent_scans(limit=10):
    """Scans recentes"""
    scans = []
    try:
        scans_dir = os.path.join(REPORTS_DIR, 'scans')
        if os.path.exists(scans_dir):
            scan_dirs = [d for d in os.listdir(scans_dir) if d.startswith('scan_')]
            scan_dirs.sort(reverse=True)
            
            for scan_dir in scan_dirs[:limit]:
                scan_path = os.path.join(scans_dir, scan_dir)
                meta_file = os.path.join(scan_path, 'metadata.json')
                
                if os.path.exists(meta_file):
                    with open(meta_file) as f:
                        metadata = json.load(f)
                    scans.append(metadata)
                else:
                    scans.append({
                        'id': scan_dir,
                        'target': scan_dir.split('_')[1] if '_' in scan_dir else 'unknown',
                        'date': datetime.datetime.fromtimestamp(os.path.getctime(scan_path)).isoformat()
                    })
    except Exception as e:
        print(f"Error getting scans: {e}")
    
    return scans

def get_scan_details(scan_id):
    """Detalhes de um scan específico"""
    try:
        scan_path = os.path.join(REPORTS_DIR, 'scans', scan_id)
        if not os.path.exists(scan_path):
            return None
        
        # Carregar metadados
        meta_file = os.path.join(scan_path, 'metadata.json')
        if os.path.exists(meta_file):
            with open(meta_file) as f:
                metadata = json.load(f)
        else:
            metadata = {
                'id': scan_id,
                'target': scan_id.split('_')[1] if '_' in scan_id else 'unknown',
                'date': datetime.datetime.fromtimestamp(os.path.getctime(scan_path)).isoformat()
            }
        
        # Carregar módulos
        modules = {}
        modules_dir = os.path.join(scan_path, 'modules')
        if os.path.exists(modules_dir):
            for mod_file in os.listdir(modules_dir):
                if mod_file.endswith('.json'):
                    with open(os.path.join(modules_dir, mod_file)) as f:
                        modules[mod_file[:-5]] = json.load(f)
        
        metadata['modules'] = modules
        return metadata
    except Exception as e:
        print(f"Error getting scan details: {e}")
        return None

def get_report_file(scan_id):
    """Arquivo de relatório"""
    scan_path = os.path.join(REPORTS_DIR, 'scans', scan_id)
    if os.path.exists(scan_path):
        for file in os.listdir(scan_path):
            if file.startswith('report.'):
                return os.path.join(scan_path, file)
    return None

def search_scans(query):
    """Buscar em scans"""
    results = []
    try:
        scans_dir = os.path.join(REPORTS_DIR, 'scans')
        if os.path.exists(scans_dir):
            for scan_dir in os.listdir(scans_dir):
                if scan_dir.startswith('scan_'):
                    modules_dir = os.path.join(scans_dir, scan_dir, 'modules')
                    if os.path.exists(modules_dir):
                        for mod_file in os.listdir(modules_dir):
                            if mod_file.endswith('.json'):
                                with open(os.path.join(modules_dir, mod_file)) as f:
                                    data = json.load(f)
                                    if query.lower() in json.dumps(data).lower():
                                        results.append({
                                            'scan_id': scan_dir,
                                            'module': mod_file[:-5],
                                            'match': 'found'
                                        })
    except Exception as e:
        print(f"Error searching: {e}")
    
    return results

def start_scan_task(target, scan_type):
    """Iniciar tarefa de scan em background"""
    import uuid
    task_id = str(uuid.uuid4())[:8]
    
    def scan_worker():
        try:
            socketio.emit('scan_started', {'task_id': task_id, 'target': target})
            
            # Executar scan
            cmd = ['cg', 'scan', target, '--type', scan_type, '--json']
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            active_tasks[task_id] = process
            
            # Monitorar output
            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break
                if output:
                    socketio.emit('scan_output', {
                        'task_id': task_id,
                        'output': output.strip()
                    })
            
            # Finalizado
            return_code = process.poll()
            if return_code == 0:
                socketio.emit('scan_complete', {
                    'task_id': task_id,
                    'success': True
                })
            else:
                socketio.emit('scan_complete', {
                    'task_id': task_id,
                    'success': False,
                    'error': process.stderr.read()
                })
            
        except Exception as e:
            socketio.emit('scan_error', {
                'task_id': task_id,
                'error': str(e)
            })
        finally:
            if task_id in active_tasks:
                del active_tasks[task_id]
    
    # Iniciar thread
    thread = threading.Thread(target=scan_worker)
    thread.daemon = True
    thread.start()
    
    return task_id

def stop_scan_task(task_id):
    """Parar tarefa de scan"""
    if task_id in active_tasks:
        process = active_tasks[task_id]
        process.terminate()
        del active_tasks[task_id]
        socketio.emit('scan_stopped', {'task_id': task_id})

def load_config():
    """Carregar configurações"""
    config_file = os.path.expanduser("~/.cyberghost/settings.conf")
    config = {}
    
    if os.path.exists(config_file):
        with open(config_file) as f:
            for line in f:
                if '=' in line and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    config[key] = value.strip('"\'')
    
    return config

def save_config(config):
    """Salvar configurações"""
    config_file = os.path.expanduser("~/.cyberghost/settings.conf")
    
    with open(config_file, 'w') as f:
        f.write("# CYBERGHOST OSINT Configuration\n")
        f.write(f"# Updated: {datetime.datetime.now().isoformat()}\n\n")
        
        for key, value in config.items():
            f.write(f"{key}=\"{value}\"\n")

def export_scan_data(scan_id, format):
    """Exportar dados do scan"""
    scan_data = get_scan_details(scan_id)
    if not scan_data:
        return None
    
    export_dir = os.path.join(REPORTS_DIR, 'exports')
    os.makedirs(export_dir, exist_ok=True)
    
    export_file = os.path.join(export_dir, f"{scan_id}_export.{format}")
    
    if format == 'json':
        with open(export_file, 'w') as f:
            json.dump(scan_data, f, indent=2)
    elif format == 'csv':
        import csv
        with open(export_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['Module', 'Key', 'Value'])
            for module, data in scan_data.get('modules', {}).items():
                if isinstance(data, dict):
                    for key, value in data.items():
                        writer.writerow([module, key, value])
    elif format == 'txt':
        with open(export_file, 'w') as f:
            f.write(f"CYBERGHOST OSINT Report - {scan_id}\n")
            f.write("=" * 50 + "\n\n")
            for module, data in scan_data.get('modules', {}).items():
                f.write(f"\n{module.upper()}:\n")
                f.write("-" * 30 + "\n")
                f.write(json.dumps(data, indent=2))
                f.write("\n")
    
    return export_file

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=8080, debug=True)