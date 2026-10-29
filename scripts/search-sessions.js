// One-off: search local Copilot session store for a term and print matching sessions.
const { DatabaseSync } = require('node:sqlite');
const db = new DatabaseSync(
  'C:/Users/Hardik/AppData/Roaming/Code/User/globalStorage/github.copilot-chat/session-store.db',
  { readOnly: true }
);
const term = process.argv[2] || 'Revisions_Needed';
const rows = db.prepare('SELECT DISTINCT session_id FROM search_index WHERE search_index MATCH ?').all(term);
console.log('FTS matches:', rows.length);
for (const r of rows) {
  const s = db.prepare('SELECT id, summary, branch, created_at, updated_at FROM sessions WHERE id = ?').get(r.session_id);
  if (s) console.log(JSON.stringify(s));
}
// Map the conversation flow of the earliest matching session
if (rows.length) {
  const first = rows[0].session_id;
  const all = db.prepare(
    "SELECT turn_index, length(COALESCE(user_message,'')) AS ulen, substr(COALESCE(user_message,''), 1, 150) AS um, timestamp FROM turns WHERE session_id = ? AND turn_index <= 15 ORDER BY turn_index"
  ).all(first);
  console.log('\nConversation flow (user msgs, first 15 turns):');
  all.forEach(t => console.log(`turn ${t.turn_index} [len ${t.ulen}]: ${t.um.replace(/\n/g, ' | ')}`));
  // full text of the ticket paste (turn 0) — as much as is stored
  const t0 = db.prepare('SELECT user_message FROM turns WHERE session_id = ? AND turn_index = 0').get(first);
  console.log('\n=== Turn 0 full stored user message ===\n' + (t0 ? t0.user_message : '(none)'));
}
