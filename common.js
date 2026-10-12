const sb=window.supabase.createClient(window.MANS_CONFIG.url,window.MANS_CONFIG.key);
const $=s=>document.querySelector(s);
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=d=>d?new Intl.DateTimeFormat('ar-IQ',{dateStyle:'medium',timeStyle:'short',timeZone:'Asia/Baghdad'}).format(new Date(d)):'—';
const logo=t=>t?.logo_url?`<img class="logo" src="${esc(t.logo_url)}" alt="شعار ${esc(t.name)}" onerror="this.style.display='none'">`:'<span class="placeholder">⚽</span>';
const getAll=async()=>{const names=['mans_teams','mans_tournaments','mans_tournament_teams','mans_matches'];const r=await Promise.all(names.map(n=>sb.from(n).select('*')));r.forEach(x=>{if(x.error)throw x.error});return Object.fromEntries(names.map((n,i)=>[n,r[i].data]));};
const statusLabel={scheduled:'قادمة',live:'مباشرة',finished:'انتهت',postponed:'مؤجلة',cancelled:'ملغاة'};
