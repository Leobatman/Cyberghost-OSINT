// =============================================================================
// CYBERGHOST OSINT ULTIMATE - Main JavaScript
// =============================================================================

// ===== GLOBAL VARIABLES =====
const API_BASE = '/api';
let socket = null;
let activeScans = new Map();

// ===== INITIALIZATION =====
document.addEventListener('DOMContentLoaded', function() {
    initSocket();
    initTooltips();
    initPopovers();
    initDataTables();
    initCharts();
    initTerminal();
    initKeyboardShortcuts();
    loadSystemStatus();
    setupAutoRefresh();
});

// ===== SOCKET.IO CONNECTION =====
function initSocket() {
    socket = io({
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        reconnectionAttempts: Infinity
    });
    
    socket.on('connect', function() {
        console.log('Socket connected');
        showNotification('success', 'Connected to server');
        updateConnectionStatus(true);
    });
    
    socket.on('disconnect', function() {
        console.log('Socket disconnected');
        showNotification('warning', 'Disconnected from server');
        updateConnectionStatus(false);
    });
    
    socket.on('scan_started', function(data) {
        activeScans.set(data.task_id, data);
        updateActiveScans();
        showNotification('info', `Scan started: ${data.target}`);
        addToActivityLog('scan_started', data);
    });
    
    socket.on('scan_output', function(data) {
        addToActivityLog('scan_output', data);
        updateScanOutput(data.task_id, data.output);
    });
    
    socket.on('scan_complete', function(data) {
        activeScans.delete(data.task_id);
        updateActiveScans();
        
        if (data.success) {
            showNotification('success', `Scan completed: ${data.task_id}`);
        } else {
            showNotification('error', `Scan failed: ${data.task_id} - ${data.error}`);
        }
        
        addToActivityLog('scan_complete', data);
    });
    
    socket.on('scan_error', function(data) {
        showNotification('error', `Scan error: ${data.error}`);
        addToActivityLog('scan_error', data);
    });
    
    socket.on('config_updated', function(data) {
        showNotification('info', 'Configuration updated');
        loadSystemStatus();
    });
}

// ===== TOOLTIPS & POPOVERS =====
function initTooltips() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
}

function initPopovers() {
    const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.map(function(popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });
}

// ===== DATA TABLES =====
function initDataTables() {
    if (typeof $.fn.DataTable !== 'undefined') {
        $('.data-table').DataTable({
            pageLength: 25,
            responsive: true,
            dom: 'Bfrtip',
            buttons: [
                'copy', 'csv', 'excel', 'pdf', 'print'
            ],
            language: {
                url: '//cdn.datatables.net/plug-ins/1.11.5/i18n/pt-BR.json'
            }
        });
    }
}

// ===== CHARTS =====
function initCharts() {
    // Charts will be initialized per page
}

function createLineChart(elementId, labels, datasets, options = {}) {
    const ctx = document.getElementById(elementId)?.getContext('2d');
    if (!ctx) return null;
    
    const defaultOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                labels: {
                    color: '#00ff00'
                }
            }
        },
        scales: {
            x: {
                grid: {
                    color: '#333333'
                },
                ticks: {
                    color: '#888888'
                }
            },
            y: {
                grid: {
                    color: '#333333'
                },
                ticks: {
                    color: '#888888'
                }
            }
        }
    };
    
    return new Chart(ctx, {
        type: 'line',
        data: { labels, datasets },
        options: { ...defaultOptions, ...options }
    });
}

function createBarChart(elementId, labels, datasets, options = {}) {
    const ctx = document.getElementById(elementId)?.getContext('2d');
    if (!ctx) return null;
    
    const defaultOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                labels: {
                    color: '#00ff00'
                }
            }
        },
        scales: {
            x: {
                grid: {
                    color: '#333333'
                },
                ticks: {
                    color: '#888888'
                }
            },
            y: {
                grid: {
                    color: '#333333'
                },
                ticks: {
                    color: '#888888'
                }
            }
        }
    };
    
    return new Chart(ctx, {
        type: 'bar',
        data: { labels, datasets },
        options: { ...defaultOptions, ...options }
    });
}

function createPieChart(elementId, labels, data, options = {}) {
    const ctx = document.getElementById(elementId)?.getContext('2d');
    if (!ctx) return null;
    
    const defaultOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                labels: {
                    color: '#00ff00'
                }
            }
        }
    };
    
    return new Chart(ctx, {
        type: 'pie',
        data: { labels, datasets: [{ data, backgroundColor: generateColors(data.length) }] },
        options: { ...defaultOptions, ...options }
    });
}

function generateColors(count) {
    const colors = [];
    for (let i = 0; i < count; i++) {
        const hue = (i * 360 / count) % 360;
        colors.push(`hsl(${hue}, 100%, 50%)`);
    }
    return colors;
}

// ===== TERMINAL =====
function initTerminal() {
    document.querySelectorAll('.terminal').forEach(terminal => {
        terminal.addEventListener('click', function() {
            // Auto-scroll to bottom on click
            this.scrollTop = this.scrollHeight;
        });
    });
}

function addTerminalLine(terminalId, text, type = 'output') {
    const terminal = document.getElementById(terminalId);
    if (!terminal) return;
    
    const line = document.createElement('div');
    line.className = 'terminal-line';
    
    const timestamp = new Date().toLocaleTimeString();
    
    switch(type) {
        case 'prompt':
            line.innerHTML = `<span class="terminal-prompt">[${timestamp}] $</span> <span class="terminal-command">${text}</span>`;
            break;
        case 'command':
            line.innerHTML = `<span class="terminal-command">${text}</span>`;
            break;
        case 'output':
            line.innerHTML = `<span class="terminal-output">${text}</span>`;
            break;
        case 'error':
            line.innerHTML = `<span class="text-danger">${text}</span>`;
            break;
        default:
            line.textContent = text;
    }
    
    terminal.appendChild(line);
    terminal.scrollTop = terminal.scrollHeight;
}

function clearTerminal(terminalId) {
    const terminal = document.getElementById(terminalId);
    if (terminal) {
        terminal.innerHTML = '';
    }
}

// ===== KEYBOARD SHORTCUTS =====
function initKeyboardShortcuts() {
    document.addEventListener('keydown', function(e) {
        // Ctrl + N - New scan
        if (e.ctrlKey && e.key === 'n') {
            e.preventDefault();
            const modal = document.getElementById('newScanModal');
            if (modal) {
                const bsModal = new bootstrap.Modal(modal);
                bsModal.show();
            }
        }
        
        // Ctrl + R - Refresh
        if (e.ctrlKey && e.key === 'r') {
            e.preventDefault();
            refreshData();
        }
        
        // Ctrl + S - Save/Settings
        if (e.ctrlKey && e.key === 's') {
            e.preventDefault();
            const saveButton = document.querySelector('[onclick="saveAllSettings()"]');
            if (saveButton) saveButton.click();
        }
        
        // Esc - Close modals
        if (e.key === 'Escape') {
            const modals = document.querySelectorAll('.modal.show');
            modals.forEach(modal => {
                const bsModal = bootstrap.Modal.getInstance(modal);
                if (bsModal) bsModal.hide();
            });
        }
        
        // ? - Show help
        if (e.key === '?' || (e.ctrlKey && e.key === 'h')) {
            e.preventDefault();
            showKeyboardHelp();
        }
    });
}

function showKeyboardHelp() {
    const help = `
        <h5>Keyboard Shortcuts</h5>
        <table class="table table-sm">
            <tr><td><kbd>Ctrl + N</kbd></td><td>New scan</td></tr>
            <tr><td><kbd>Ctrl + R</kbd></td><td>Refresh data</td></tr>
            <tr><td><kbd>Ctrl + S</kbd></td><td>Save settings</td></tr>
            <tr><td><kbd>Esc</kbd></td><td>Close modal</td></tr>
            <tr><td><kbd>?</kbd></td><td>Show this help</td></tr>
        </table>
    `;
    
    Swal.fire({
        title: 'Keyboard Shortcuts',
        html: help,
        icon: 'info',
        confirmButtonColor: '#00ff00'
    });
}

// ===== SYSTEM STATUS =====
function loadSystemStatus() {
    fetch(`${API_BASE}/status`)
        .then(response => response.json())
        .then(data => {
            updateSystemStatus(data);
        })
        .catch(error => {
            console.error('Failed to load system status:', error);
        });
}

function updateSystemStatus(data) {
    const statusEl = document.getElementById('systemStatus');
    if (!statusEl) return;
    
    statusEl.innerHTML = `
        <div class="small">
            <div class="d-flex justify-content-between">
                <span>Status:</span>
                <span class="badge bg-success">${data.status}</span>
            </div>
            <div class="d-flex justify-content-between mt-2">
                <span>Version:</span>
                <span>${data.version}</span>
            </div>
            <div class="d-flex justify-content-between mt-2">
                <span>Uptime:</span>
                <span>${formatUptime(data.uptime)}</span>
            </div>
            <div class="progress mt-2" style="height: 5px;">
                <div class="progress-bar" style="width: ${data.cpu}%"></div>
            </div>
            <div class="progress mt-1" style="height: 5px;">
                <div class="progress-bar" style="width: ${data.memory}%"></div>
            </div>
            <div class="progress mt-1" style="height: 5px;">
                <div class="progress-bar" style="width: ${data.disk}%"></div>
            </div>
        </div>
    `;
}

function updateConnectionStatus(connected) {
    const indicator = document.getElementById('connectionStatus');
    if (indicator) {
        indicator.className = `badge bg-${connected ? 'success' : 'danger'}`;
        indicator.textContent = connected ? 'Connected' : 'Disconnected';
    }
}

function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
}

// ===== NOTIFICATIONS =====
function showNotification(type, message, duration = 5000) {
    const toast = document.getElementById('liveToast');
    const toastBody = document.getElementById('toastMessage');
    
    if (!toast || !toastBody) {
        alert(message);
        return;
    }
    
    toastBody.textContent = message;
    
    const toastHeader = toast.querySelector('.toast-header');
    toastHeader.className = 'toast-header';
    
    switch(type) {
        case 'success':
            toastHeader.classList.add('bg-success', 'text-white');
            break;
        case 'error':
            toastHeader.classList.add('bg-danger', 'text-white');
            break;
        case 'warning':
            toastHeader.classList.add('bg-warning');
            break;
        case 'info':
            toastHeader.classList.add('bg-info');
            break;
    }
    
    const bsToast = new bootstrap.Toast(toast, { delay: duration });
    bsToast.show();
}

// ===== ACTIVITY LOG =====
function addToActivityLog(type, data) {
    const log = document.getElementById('activityLog');
    if (!log) return;
    
    const entry = document.createElement('div');
    entry.className = 'activity-entry mb-2 small';
    
    const time = new Date().toLocaleTimeString();
    
    switch(type) {
        case 'scan_started':
            entry.innerHTML = `<span class="text-info">[${time}]</span> Started scan on <strong>${data.target}</strong> (ID: ${data.task_id})`;
            break;
        case 'scan_output':
            entry.innerHTML = `<span class="text-muted">[${time}]</span> ${data.output}`;
            break;
        case 'scan_complete':
            if (data.success) {
                entry.innerHTML = `<span class="text-success">[${time}]</span> Scan ${data.task_id} completed successfully`;
            } else {
                entry.innerHTML = `<span class="text-danger">[${time}]</span> Scan ${data.task_id} failed: ${data.error}`;
            }
            break;
        case 'scan_error':
            entry.innerHTML = `<span class="text-danger">[${time}]</span> Error: ${data.error}`;
            break;
    }
    
    log.insertBefore(entry, log.firstChild);
    
    // Limit log entries
    while (log.children.length > 100) {
        log.removeChild(log.lastChild);
    }
}

// ===== ACTIVE SCANS =====
function updateActiveScans() {
    const container = document.getElementById('activeScans');
    if (!container) return;
    
    if (activeScans.size === 0) {
        container.innerHTML = '<div class="text-muted">No active scans</div>';
        return;
    }
    
    let html = '';
    activeScans.forEach((scan, id) => {
        html += `
            <div class="scan-item mb-2 p-2 border rounded">
                <div class="d-flex justify-content-between">
                    <span><strong>${scan.target}</strong></span>
                    <span class="badge bg-warning">Running</span>
                </div>
                <div class="small text-muted">ID: ${id}</div>
                <div class="progress mt-1" style="height: 3px;">
                    <div class="progress-bar progress-bar-striped progress-bar-animated" style="width: 100%"></div>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

function updateScanOutput(taskId, output) {
    // Implement per-scan output display
}

// ===== DATA REFRESH =====
let refreshInterval = null;

function setupAutoRefresh(interval = 30000) {
    if (refreshInterval) clearInterval(refreshInterval);
    refreshInterval = setInterval(refreshData, interval);
}

function refreshData() {
    loadSystemStatus();
    
    // Dispatch refresh event for specific pages
    const event = new CustomEvent('cyberghost-refresh');
    document.dispatchEvent(event);
}

// ===== UTILITY FUNCTIONS =====
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
    
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

function formatDuration(seconds) {
    if (seconds < 60) return `${seconds}s`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
    return `${Math.floor(seconds / 3600)}h ${Math.floor((seconds % 3600) / 60)}m`;
}

function formatDate(date) {
    return new Date(date).toLocaleString();
}

function getQueryParam(name) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(name);
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showNotification('success', 'Copied to clipboard');
    }).catch(() => {
        // Fallback
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showNotification('success', 'Copied to clipboard');
    });
}

function downloadAsFile(content, filename, type = 'text/plain') {
    const blob = new Blob([content], { type });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
}

function saveAsFile(filename, content, mimeType = 'application/octet-stream') {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 100);
}

function readFileAsText(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = e => resolve(e.target.result);
        reader.onerror = e => reject(e.target.error);
        reader.readAsText(file);
    });
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = setTimeout(() => inThrottle = false, limit);
        }
    };
}

// ===== EXPORTS =====
window.CyberGhost = {
    api: API_BASE,
    socket,
    activeScans,
    showNotification,
    refreshData,
    copyToClipboard,
    downloadAsFile,
    formatBytes,
    formatDuration,
    formatDate,
    debounce,
    throttle
};