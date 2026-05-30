#!/usr/bin/env node

const { spawnSync, spawn } = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');

const args = process.argv.slice(2);

console.log('[*] awesome-agentic-stack — Bootstrapping Universal Installer...\n');

const platform = os.platform();
const tempDir = path.join(os.tmpdir(), 'awesome-agentic-stack-npm');

if (fs.existsSync(tempDir)) {
  try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (e) {}
}
fs.mkdirSync(tempDir, { recursive: true });

// Retry git clone with exponential backoff
console.log('  [+] Syncing installer scripts from GitHub...');
let cloned = false;
for (let attempt = 1; attempt <= 3; attempt++) {
  const result = spawnSync('git', [
    'clone', '--depth', '1',
    'https://github.com/AkashPriyadarshii/awesome-agentic-stack.git',
    tempDir
  ], { stdio: 'pipe' });

  if (result.status === 0) {
    cloned = true;
    break;
  }

  if (attempt < 3) {
    const delay = Math.min(Math.pow(2, attempt) * 1000 + Math.random() * 500, 30000);
    console.log(`  [!] Sync failed. Retrying in ${Math.round(delay / 1000)}s... (${attempt}/3)`);
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, delay);
  }
}

if (!cloned) {
  console.error('  [-] Error: Failed to fetch repository files after 3 attempts.');
  console.error('      Verify Git is installed and you are online.');
  process.exit(1);
}

// Delegate to OS-specific installer
if (platform === 'win32') {
  console.log('  [+] Windows OS detected. Launching PowerShell Installer...');
  const psScript = path.join(tempDir, 'install.ps1');
  const psArgs = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', psScript];

  args.forEach(arg => {
    if (arg === '--essential' || arg === '-e') psArgs.push('-Essential');
    if (arg === '--interactive' || arg === '-i') psArgs.push('-Interactive');
    if (arg === '--yes' || arg === '-y') psArgs.push('-Yes');
    if (arg === '--list' || arg === '-l') psArgs.push('-List');
    if (arg === '--dry-run' || arg === '-d') psArgs.push('-DryRun');
    if (arg === '--resume' || arg === '-r') psArgs.push('-Resume');
  });

  const installProc = spawn('powershell.exe', psArgs, { stdio: 'inherit' });
  installProc.on('close', (code) => process.exit(code));
} else {
  console.log('  [+] macOS/Linux detected. Launching Bash Installer...');
  const shScript = path.join(tempDir, 'install.sh');
  fs.chmodSync(shScript, '755');

  const installProc = spawn('/usr/bin/env', ['bash', shScript, ...args], { stdio: 'inherit' });
  installProc.on('close', (code) => process.exit(code));
}
