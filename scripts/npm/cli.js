#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Fetch clean CLI arguments
const args = process.argv.slice(2);

console.log('[*] awesome-agentic-stack — Bootstrapping Universal Installer...\n');

// Detect Platform
const platform = os.platform();
const tempDir = path.join(os.tmpdir(), 'awesome-agentic-stack-npm');

// Ensure clean temp dir
if (fs.existsSync(tempDir)) {
  try {
    fs.rmSync(tempDir, { recursive: true, force: true });
  } catch (e) {
    // Silently continue
  }
}
fs.mkdirSync(tempDir, { recursive: true });

// Step 1: Clone the repository to fetch the latest installers and manifest
console.log('  [+] Syncing installer scripts from GitHub...');
const gitClone = spawn('git', [
  'clone',
  '--depth', '1',
  'https://github.com/AkashPriyadarshii/awesome-agentic-stack.git',
  tempDir
]);

gitClone.on('close', (code) => {
  if (code !== 0) {
    console.error('  [-] Error: Failed to fetch repository files. Verify Git is installed and you are online.');
    process.exit(1);
  }

  // Step 2: OS Specific Installer Delegation
  if (platform === 'win32') {
    // Windows PowerShell execution
    console.log('  [+] Windows OS detected. Launching PowerShell Installer...');
    const psScript = path.join(tempDir, 'install.ps1');
    const psArgs = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', psScript];
    
    // Map npm arguments to PowerShell switch arguments
    args.forEach(arg => {
      if (arg === '--essential' || arg === '-e') psArgs.push('-Essential');
      if (arg === '--interactive' || arg === '-i') psArgs.push('-Interactive');
      if (arg === '--yes' || arg === '-y') psArgs.push('-Yes');
      if (arg === '--list' || arg === '-l') psArgs.push('-List');
      if (arg === '--dry-run' || arg === '-d') psArgs.push('-DryRun');
      if (arg === '--resume' || arg === '-r') psArgs.push('-Resume');
    });

    const installProc = spawn('powershell.exe', psArgs, { stdio: 'inherit' });
    installProc.on('close', (exitCode) => process.exit(exitCode));
  } else {
    // macOS or Linux Bash execution
    console.log('  [+] macOS/Linux detected. Launching Bash Installer...');
    const shScript = path.join(tempDir, 'install.sh');
    
    // Make script executable
    fs.chmodSync(shScript, '755');

    const installProc = spawn('/usr/bin/env', ['bash', shScript, ...args], { stdio: 'inherit' });
    installProc.on('close', (exitCode) => process.exit(exitCode));
  }
});
