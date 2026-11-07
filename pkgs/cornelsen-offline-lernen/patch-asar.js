const fs = require('fs');
const path = require('path');
const root = process.argv[2];

const distDir = path.join(root, 'dist');
if (!fs.existsSync(distDir)) {
    console.error('ERROR: unpacked asar does not contain a dist directory');
    process.exit(1);
}

function collectJsFiles(dir, out = []) {
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, ent.name);
        if (ent.isDirectory()) { collectJsFiles(p, out); }
        else if (ent.isFile() && ent.name.endsWith('.js')) { out.push(p); }
    }
    return out;
}

const jsFiles = collectJsFiles(distDir);
const DOL = '$' + '{';

const patches = [
    {
        name: 'annotations-404-fallback',
        from: 'getProductAnnotations(t){return this.http.get(`' + DOL + 'Na.getApiBaseUrl()}/pspdf/all-annotations/' + DOL + 't}`).pipe(Qr(i=>(i||[]).reduce((c,q)=>{var ce=q,{documentId:v}=ce;return c[v]=ft(ce,[`documentId`]),c},{})),fl(i=>this.mapOfflinePdfIds(i)))}',
        to: 'getProductAnnotations(t){return this.http.get(`' + DOL + 'Na.getApiBaseUrl()}/pspdf/all-annotations/' + DOL + 't}`).pipe(Jd(i=>{if(i.status===404)return Qa([]);throw i}),Qr(i=>(i||[]).reduce((c,q)=>{var ce=q,{documentId:v}=ce;return c[v]=ft(ce,[`documentId`]),c},{})),fl(i=>this.mapOfflinePdfIds(i)))}',
        required: false
    },
    {
        name: 'compatibility-401-fallback',
        from: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'Na.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'dC}`).pipe(Qr((t=>t.isCompatible)))}',
        to: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'Na.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'dC}`).pipe(Qr((t=>t.isCompatible)),Jd(t=>{if(t.status===401)return Qa(!0);throw t}))}',
        required: false
    }
];

const applied = new Set();
for (const p of patches) {
    for (const filePath of jsFiles) {
        let txt = fs.readFileSync(filePath, 'utf8');
        if (txt.includes(p.from)) {
            txt = txt.replace(p.from, p.to);
            fs.writeFileSync(filePath, txt);
            applied.add(p.name);
            break;
        }
        if (p.fromAlt && p.toAlt && txt.includes(p.fromAlt)) {
            txt = txt.replace(p.fromAlt, p.toAlt);
            fs.writeFileSync(filePath, txt);
            applied.add(p.name);
            break;
        }
        if (p.fromAlt2 && p.toAlt2 && txt.includes(p.fromAlt2)) {
            txt = txt.replace(p.fromAlt2, p.toAlt2);
            fs.writeFileSync(filePath, txt);
            applied.add(p.name);
            break;
        }
        if (p.fromAlt3 && p.toAlt3 && txt.includes(p.fromAlt3)) {
            txt = txt.replace(p.fromAlt3, p.toAlt3);
            fs.writeFileSync(filePath, txt);
            applied.add(p.name);
            break;
        }
    }
}

for (const p of patches) {
    if (!applied.has(p.name)) {
        console.error('WARNING: patch ' + p.name + ' did not apply (minified names changed?)');
        if (p.required) { process.exit(1); }
    }
}
