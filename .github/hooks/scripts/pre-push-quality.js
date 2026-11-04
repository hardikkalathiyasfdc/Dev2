#!/usr/bin/env node
/**
 * Pre-push quality gate (WARN-ONLY - never blocks).
 *
 * Fires PreToolUse on every tool call; bails in <50ms unless the tool input
 * looks like a `git push` (single regex, no AI calls). On a push it runs:
 *   - PMD via `sf scanner run --engine pmd` on changed Apex (.cls/.trigger)
 *   - eslint on changed aura/lwc JS
 * across working-tree changes (vs HEAD), unpushed commits (origin/main...HEAD)
 * and untracked files, then emits a systemMessage with violation counts and the
 * top High/Moderate findings so the agent can fix them per the git-push-checks
 * skill.
 *
 * Bypass: put SKIP_QUALITY anywhere in the command.
 * Contract: always exit 0; any internal error is swallowed so pushes never break.
 */
'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const GIT_EXE = 'C:\\Program Files\\Git\\cmd\\git.exe';
const MAX_LISTED = 12;

function allow(message) {
  if (message) {
    process.stdout.write(JSON.stringify({ continue: true, systemMessage: message }));
  }
  process.exit(0);
}

async function main() {
  let input = '';
  process.stdin.setEncoding('utf8');
  for await (const chunk of process.stdin) input += chunk;
  if (!input) allow();

  // Detect git push: `git push`, `& "C:\...\git.exe" push origin main`, `$g push origin`.
  // One regex, no token-heavy AI involvement - keep this hook cheap.
  const isPush = /\bgit\b.*\bpush\b/i.test(input) || /\bpush\s+origin\b/i.test(input);
  if (!isPush) allow();
  if (/SKIP_QUALITY/i.test(input)) allow();

  const gitBin = fs.existsSync(GIT_EXE) ? GIT_EXE : 'git';
  const runGit = (args, cwd) => {
    const r = spawnSync(gitBin, args, { cwd: cwd || process.cwd(), encoding: 'utf8', timeout: 20000, shell: false });
    return r && r.status === 0 && r.stdout ? r.stdout : '';
  };

  const root = runGit(['rev-parse', '--show-toplevel']).trim().replace(/\//g, path.sep);
  if (!root) allow();

  const changed = new Set();
  for (const out of [
    runGit(['diff', '--name-only', 'HEAD'], root),
    runGit(['diff', '--name-only', 'origin/main...HEAD'], root),
    runGit(['ls-files', '--others', '--exclude-standard'], root),
  ]) {
    out.split(/\r?\n/).map((s) => s.trim()).filter(Boolean).forEach((f) => changed.add(f));
  }

  const abs = [...changed].map((f) => path.join(root, f)).filter((f) => fs.existsSync(f));
  const apex = abs.filter((f) => /\.(cls|trigger)$/i.test(f) && /force-app/i.test(f));
  const js = abs.filter((f) => /\.js$/i.test(f) && /(aura|lwc)[\\/]/i.test(f) && !/(__tests__|\.test\.js$)/i.test(f));
  if (!apex.length && !js.length) allow();

  const lines = [];
  const findings = [];

  // --- PMD on changed Apex (one batched scanner run via shared runner; auto-picks pmd/apex-ruleset.xml) ---
  if (apex.length) {
    const out = path.join(os.tmpdir(), `pre-push-pmd-${Date.now()}.json`);
    const runner = path.join(root, 'scripts', 'pmd', 'Invoke-PmdScan.ps1');
    const args = fs.existsSync(runner)
      ? ['-File', runner, '-Targets', ...apex, '-Format', 'json', '-OutFile', out, '-Quiet']
      : ['scanner', 'run', '--engine', 'pmd', '--normalize-severity', '--format', 'json', '--outfile', out, ...apex.flatMap((f) => ['--target', f])];
    const cmd = fs.existsSync(runner) ? 'pwsh' : 'sf';
    spawnSync(cmd, args, { cwd: root, shell: true, timeout: 240000, stdio: 'ignore' });
    if (fs.existsSync(out)) {
      try {
        const data = JSON.parse(fs.readFileSync(out, 'utf8'));
        if (Array.isArray(data)) {
          // v4 scanner: [{ engine, fileName, violations: [{ line, normalizedSeverity|severity, ruleName, message }] }]
          for (const row of data) {
            for (const v of row.violations || []) {
              findings.push({
                file: row.fileName,
                line: v.line,
                sev: v.normalizedSeverity != null ? v.normalizedSeverity : v.severity,
                rule: v.ruleName,
                msg: String(v.message || '').trim().replace(/\s+/g, ' '),
              });
            }
          }
        } else {
          // v5 code-analyzer: { violations: [{ rule, severity (1-5), locations: [{ file, startLine }], primaryLocationIndex, message }] }
          for (const v of data.violations || []) {
            const loc = (v.locations || [])[v.primaryLocationIndex != null ? v.primaryLocationIndex : 0] || {};
            findings.push({
              file: loc.file || '',
              line: loc.startLine || 0,
              sev: v.severity, // 1=Critical 2=High 3=Moderate 4=Low 5=Info
              rule: v.rule,
              msg: String(v.message || '').trim().replace(/\s+/g, ' '),
            });
          }
        }
      } catch (e) { lines.push('PMD output unparseable - skipped.'); }
      try { fs.unlinkSync(out); } catch (e) { /* ignore */ }
    } else {
      lines.push('PMD produced no results (scanner error or not installed) - skipped.');
    }
  }

  // --- eslint on changed aura/lwc JS ---
  const lintIssues = [];
  if (js.length) {
    const bin = path.join(root, 'node_modules', '.bin', 'eslint.cmd');
    if (fs.existsSync(bin)) {
      const r = spawnSync(bin, ['--format', 'json', ...js], { cwd: root, shell: true, timeout: 120000, encoding: 'utf8' });
      if (r.stdout) {
        try {
          for (const row of JSON.parse(r.stdout)) {
            for (const m of row.messages || []) {
              if (m.severity >= 1) {
                lintIssues.push({ file: row.filePath, line: m.line, error: m.severity === 2, rule: m.ruleId || '', msg: String(m.message || '').trim().replace(/\s+/g, ' ') });
              }
            }
          }
        } catch (e) { lines.push('eslint output unparseable - skipped.'); }
      }
    } else {
      lines.push('eslint not installed (node_modules missing) - skipped.');
    }
  }

  const sev = (n) => findings.filter((f) => f.sev === n);
  // High = sev 1 (v4 High / v5 Critical) + sev 2 (v4 Moderate / v5 High); both gates honor sev<=2.
  const lintErrors = lintIssues.filter((i) => i.error);
  const clean = findings.length === 0 && lintIssues.length === 0;

  if (clean) {
    allow(`[pre-push quality gate] Clean: PMD on ${apex.length} Apex file(s), eslint on ${js.length} JS file(s) - no violations.`);
  }

  lines.unshift(`[pre-push quality gate] PMD (${apex.length} Apex file(s)): sev1=${sev(1).length} sev2=${sev(2).length} sev3=${sev(3).length} other=${Math.max(0, findings.length - sev(1).length - sev(2).length - sev(3).length)} | eslint (${js.length} JS file(s)): errors=${lintErrors.length} warnings=${lintIssues.length - lintErrors.length}`);
  for (const f of [...sev(1), ...sev(2)].slice(0, MAX_LISTED)) {
    lines.push(`PMD sev${f.sev} ${path.relative(root, f.file)}:${f.line} ${f.rule} - ${f.msg}`.slice(0, 300));
  }
  for (const i of lintErrors.slice(0, 8)) {
    lines.push(`eslint ERROR ${path.relative(root, i.file)}:${i.line} ${i.rule} - ${i.msg}`.slice(0, 300));
  }
  lines.push('Warn-only: push allowed. Per .github/skills/git-push-checks/SKILL.md, fix High/Moderate PMD + eslint errors on touched code in a follow-up commit before calling the task done. Bypass: SKIP_QUALITY in the push command.');
  allow(lines.join('\n'));
}

main().catch(() => allow());
