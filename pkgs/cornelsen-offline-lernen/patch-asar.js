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
        from: 'getProductAnnotations(r,s=!1){return this.http.get(`' + DOL + 's?os.getSyncApiBaseUrl():os.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'r}`).pipe(ip(y=>r0(()=>y)),Jl(y=>this.mapOfflinePdfIds(y)))}',
        fromAlt: 'getProductAnnotations(r,s=!1){return this.http.get(`' + DOL + 's?ls.getSyncApiBaseUrl():ls.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'r}`).pipe(nc(y=>this.mapOfflinePdfIds(y)))}',
        toAlt: 'getProductAnnotations(r,s=!1){return this.http.get(`' + DOL + 's?ls.getSyncApiBaseUrl():ls.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'r}`).pipe(op(y=>s&&y.status===404?fs({}):r0(()=>y)),nc(y=>this.mapOfflinePdfIds(y)))}',
        fromAlt2: 'getProductAnnotations(r,s=!1){return this.http.get(`' + DOL + 's?cs.getSyncApiBaseUrl():cs.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'r}`).pipe(nc(y=>this.mapOfflinePdfIds(y)))}',
        toAlt2: 'getProductAnnotations(r,s=!1){return this.http.get(`' + DOL + 's?cs.getSyncApiBaseUrl():cs.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'r}`).pipe(op(y=>s&&y.status===404?Es({}):r0(()=>y)),nc(y=>this.mapOfflinePdfIds(y)))}',
        fromAlt3: 'getProductAnnotations(i,s=!1){return this.http.get(`' + DOL + 's?cs.getSyncApiBaseUrl():cs.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'i}`).pipe(nc(y=>this.mapOfflinePdfIds(y)))}',
        toAlt3: 'getProductAnnotations(i,s=!1){return this.http.get(`' + DOL + 's?cs.getSyncApiBaseUrl():cs.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'i}`).pipe(ip(y=>{if(s&&y.status===404)return _s({});throw y}),nc(y=>this.mapOfflinePdfIds(y)))}',
        to: 'getProductAnnotations(r,s=!1){return this.http.get(`' + DOL + 's?os.getSyncApiBaseUrl():os.getApiBaseUrl()}/pspdf/annotations/' + DOL + 'r}`).pipe(ip(y=>s&&y.status===404?hs({}):r0(()=>y)),Jl(y=>this.mapOfflinePdfIds(y)))}',
        required: false
    },
    {
        name: 'compatibility-401-fallback',
        from: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'os.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'GE}`).pipe(sa(r=>r.isCompatible))}',
        fromAlt: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'ls.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'qE}`).pipe(sa(r=>r.isCompatible))}',
        toAlt: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'ls.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'qE}`).pipe(sa(r=>r.isCompatible),op(r=>r.status===401?fs(!0):r0(()=>r)))}',
        fromAlt2: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'cs.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'ZE}`).pipe(sa(r=>r.isCompatible))}',
        toAlt2: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'cs.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'ZE}`).pipe(sa(r=>r.isCompatible),op(r=>r.status===401?Es(!0):r0(()=>r)))}',
        fromAlt3: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'cs.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'QE}`).pipe(ta(i=>i.isCompatible))}',
        toAlt3: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'cs.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'QE}`).pipe(ta(i=>i.isCompatible),ip(r=>{if(r.status===401)return _s(!0);throw r}))}',
        to: 'isCompatibleWithOnline$(){return this.http.get(`' + DOL + 'os.getSyncApiBaseUrl()}/compatibility/offlineClients/' + DOL + 'GE}`).pipe(sa(r=>r.isCompatible),ip(r=>r.status===401?hs(!0):r0(()=>r)))}',
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
