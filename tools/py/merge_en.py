#!/usr/bin/env python3
"""Merge hand translations (script/src/*.txt, 'ID text' per line) into script/en/*.json.
Needs the JP script dump in build/jp (python3 tools/py/dump_script.py, reads your ROM) for message structure,
dedup (identical JP text reuses the same translation) and tag/terminator validation.
The written script/en/*.json files are English-only: IDs, structure and "en" text; no Japanese text or ROM bytes."""
import json, glob, os, re, sys, collections
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
JP = os.path.join(ROOT, 'build/jp'); EN = os.path.join(ROOT, 'script/en'); TR = os.path.join(ROOT, 'script/src')
JPCHARS = re.compile(r'[\u3040-\u30ff\u3400-\u9fff\uff00-\uffef]')
KEEP_INFO = ('block', 'start', 'end', 'size', 'ptr_fmt', 'ptr_loc')
KEEP_MSG = ('id', 'block', 'kind', 'label', 'snes', 'choice_jump_label', 'entry_id', 'param', 'note', 'en', 'en_from')
def english_only(d):
    info = {k: d['info'][k] for k in KEEP_INFO if k in d['info']}
    info['en_translated'] = d['info'].get('en_translated', 0); info['messages'] = len(d['messages'])
    msgs = []
    for m in d['messages']:
        o = {k: m[k] for k in KEEP_MSG if k in m}
        if 'note' in o and JPCHARS.search(str(o['note'])): del o['note']
        assert not JPCHARS.search(o.get('en', '')), m['id']
        msgs.append(o)
    return dict(info=info, messages=msgs)
os.makedirs(EN, exist_ok=True)
tr = {}
for f in sorted(glob.glob(os.path.join(TR, '*.txt'))):
    for ln in open(f, encoding='utf-8'):
        ln = ln.rstrip('\n')
        if not ln.strip() or ln.startswith('#'): continue
        i, _, t = ln.partition(' ')
        tr[i] = t
blocks = [os.path.basename(f)[:-5] for f in sorted(glob.glob(os.path.join(JP, '*.json'))) if not f.endswith('_summary.json')]
alljp = {}
for b in blocks:
    for m in json.load(open(os.path.join(JP, b + '.json'), encoding='utf-8'))['messages']:
        alljp[m['id']] = m
bytext = collections.defaultdict(list)
for i, m in alljp.items(): bytext[m['text']].append(i)
TAG = re.compile(r'\[(?:page|wait|br|hl|END|ENDK|[0-9A-Fa-f]{2})\]')
def pages(t):
    t = t.replace('[br]', ' ')
    return [TAG.sub('', p).strip() for p in t.split('[page]')]
warn = []; cov = collections.Counter(); tot = collections.Counter()
summary_lines = []
for b in blocks:
    d = json.load(open(os.path.join(JP, b + '.json'), encoding='utf-8'))
    for m in d['messages']:
        tot[b] += 1
        en = tr.get(m['id'])
        src = m['id']
        if en is None:
            for j in bytext[m['text']]:
                if j in tr: en = tr[j]; src = j; break
        if en is None and m['kind'] != 'system' and re.fullmatch(r'(?:[　 \n]|\[(?:88|br|wait|page|END|ENDK)\])*', m['text']):
            en = m['text'].rstrip('\n').replace('[br]\n', '[br]'); src = 'copy'
        if en is None:
            m.pop('en', None); continue
        if m['kind'] == 'system':
            # English-only list of the system strings (the shipped build renders these via script/en_system_layout.json)
            try: m['en'] = ' | '.join(json.loads(en))
            except Exception as e: warn.append(f"{m['id']}: bad json {e}")
        else:
            m['en'] = en
        if src != m['id']: m['en_from'] = src
        cov[b] += 1
        if m['kind'] in ('system',): continue
        jt = m['text'].rstrip('\n').replace('[br]\n', '[br]')
        jend = re.findall(r'\[(END|ENDK)\]$', jt); eend = re.findall(r'\[(END|ENDK)\]$', en)
        if jend != eend: warn.append(f"{m['id']}: terminator {jend} vs {eend}")
        for code in set(re.findall(r'\[([0-9A-Fa-f]{2})\]', jt)) - {'88'}:
            if jt.count(f'[{code}]') != en.count(f'[{code}]'): warn.append(f"{m['id']}: control [{code}] count differs")
        if en.count('[hl]') % 2: warn.append(f"{m['id']}: odd [hl]")
        jp_pre = re.match(r'^((?:\[(?:wait|page)\])*)', jt).group(1); en_pre = re.match(r'^((?:\[(?:wait|page)\])*)', en).group(1)
        if jp_pre != en_pre: warn.append(f"{m['id']}: prefix {jp_pre!r} vs {en_pre!r}")
        lim = 95 if m['kind'] in ('dialogue',) else 400
        for k, p in enumerate(pages(en)):
            if len(p) > lim: warn.append(f"{m['id']}: page {k} {len(p)} chars: {p[:60]}...")
        if m['kind'] in ('choice', 'choice3') and len(TAG.sub('', en)) > 24: warn.append(f"{m['id']}: long choice")
    d['info']['en_translated'] = cov[b]
    json.dump(english_only(d), open(os.path.join(EN, b + '.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for m in d['messages']:
        summary_lines.append(f"### {m['id']}\nJP: {m['text'].rstrip()}\nEN: {m.get('en', '<<UNTRANSLATED>>')}\n")
# side-by-side proofreading file (contains JP text from your ROM) goes to build/, never into the repo
open(os.path.join(ROOT, 'build', 'proofread_jp_en.txt'), 'w', encoding='utf-8').write('\n'.join(summary_lines))
unknown = [i for i in tr if i not in alljp]
if unknown: warn.append(f"unknown ids: {unknown}")
json.dump({b: {'translated': cov[b], 'total': tot[b]} for b in blocks}, open(os.path.join(EN, '_coverage.json'), 'w'), indent=1)
for w in warn: print('WARN', w)
print('coverage', sum(cov.values()), '/', sum(tot.values()))
for b in blocks: print(f"  {b}: {cov[b]}/{tot[b]}")
