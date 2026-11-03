# Printer

## What is configured

| | |
| --- | --- |
| Printer | Kyocera FS-3820N, monochrome laser, network (no scanner) |
| Address | `192.168.2.52` (fixed IP), web interface at <http://192.168.2.52/> |
| Ports | 9100 (raw/JetDirect), 631 (IPP 1.x only), 515 (LPD) |
| Queue name | `Kyocera_FS-3820N` (default printer) |
| Device URI | `socket://192.168.2.52:9100` |
| Driver | Kyocera's own PostScript PPD from `foomatic-db-ppds`: `foomatic-db-ppds/Kyocera-FS-3820N-Postscript-Kyocera.ppd.gz` |
| GUI | Mango: `system-config-printer` ("Print Settings"); Plasma: System Settings > Printers |

The configuration lives in two places:

- `common/base.nix`: `services.printing` (CUPS + driver package) and `hardware.printers` (the queue). Shared by both variants.
- `nixos-mango/configuration.nix`: `programs.system-config-printer.enable`. Plasma ships its own printer settings module.

```nix
services.printing = {
  enable = true;
  drivers = [ pkgs.foomatic-db-ppds ];
};
hardware.printers = {
  ensurePrinters = [
    {
      name = "Kyocera_FS-3820N";
      description = "Kyocera FS-3820N";
      location = "LAN";
      deviceUri = "socket://192.168.2.52:9100";
      model = "foomatic-db-ppds/Kyocera-FS-3820N-Postscript-Kyocera.ppd.gz";
      ppdOptions.PageSize = "A4";
    }
  ];
  ensureDefaultPrinter = "Kyocera_FS-3820N";
};
```

`hardware.printers.ensurePrinters` creates the queue every time CUPS starts (`postStart` of `cups.service`). Changes made in the GUI to this queue can be overwritten by the next `nh os switch`; change the Nix code instead.

### Why a fixed queue and not auto-discovery

Modern printers announce themselves via mDNS/Bonjour (Avahi) and speak *IPP Everywhere* (driverless). CUPS then creates a queue on its own and no driver is needed. The FS-3820N (around 2008) does neither:

- `avahi-browse -art` shows nothing for it: it does not announce itself.
- `ipptool -tv ipp://192.168.2.52/ipp get-printer-attributes.test` answers `server-error-version-not-supported`: only old IPP, no driverless printing.

So the queue has to be defined by hand, with a driver (PPD).

### Why this driver

`foomatic-db-ppds` contains six PPDs for the FS-3820N. `Kyocera-FS-3820N-Postscript-Kyocera.ppd.gz` is the manufacturer's PPD: the printer interprets PostScript itself (Kyocera "KPDL"), so no extra filter (Ghostscript/foomatic-rip) runs, and the PPD exposes the real options: duplex unit, paper feeders, output bins, resolution, KIR smoothing. The `hpijs-pcl5e`/`ljet4` PPDs are generic PCL fallbacks.

### Optional printer hardware

The PPD can't detect optional hardware. If the printer has a duplex unit or extra paper feeder, enable it once, either in the GUI (printer > Properties > Installable Options) or in Nix, so it survives rebuilds:

```nix
ppdOptions = {
  PageSize = "A4";
  Option16 = "True";   # Duplex Unit installed
};
```

The option names come from `lpoptions -p Kyocera_FS-3820N -l`.

## Everyday use

```sh
lpstat -p -d                                # printers, default printer
lp file.pdf                                 # print on the default printer
lp -n 2 -o page-ranges=1-3 file.pdf         # 2 copies of pages 1-3
lp -o sides=two-sided-long-edge file.pdf    # duplex (needs the duplex unit)
lpstat -o                                   # queued jobs
cancel -a                                   # cancel all jobs
```

CUPS web interface (local): <http://localhost:631/>. Toner level and printer status: <http://192.168.2.52/>.

## Manual steps: set up any printer on NixOS

### 1. Base services (already in `common/base.nix`)

```nix
services.printing.enable = true;     # CUPS
services.avahi = {                    # mDNS: finds network printers
  enable = true;
  nssmdns4 = true;                    # resolves *.local names
};
```

For USB printers nothing else is needed at this step.

### 2. Identify the printer

- Network: open `http://<ip>/` in a browser; the web interface shows the model. Or `curl -s http://<ip>/ | grep -i model`.
- USB: `lsusb`, or `lpinfo -v` (lists the device URIs CUPS sees, for example `usb://Brother/...`).
- Open ports: `for p in 631 9100 515; do timeout 2 bash -c "echo >/dev/tcp/<ip>/$p" && echo "open $p"; done`

### 3. Check whether it works driverless

```sh
avahi-browse -art | grep -i -A4 ipp            # does it announce itself?
ipptool -tv ipp://<ip>/ipp/print get-printer-attributes.test | grep -E 'ipp-versions|document-format'
```

If it announces itself and lists `image/pwg-raster`, `image/urf` or `application/pdf`, it is driverless: it already appears in print dialogs. To make the queue permanent, use the `everywhere` model and skip step 4:

```nix
hardware.printers.ensurePrinters = [{
  name = "MyPrinter";
  deviceUri = "ipp://<ip>/ipp/print";
  model = "everywhere";
}];
```

Most printers since about 2015 work this way. Then you don't need a driver.

### 4. Find a driver (only for printers that are not driverless)

Look up the model at <https://www.openprinting.org/printers>; it says which driver package fits. Common NixOS packages for `services.printing.drivers`:

| Package | Printers |
| --- | --- |
| `foomatic-db-ppds` (or `foomatic-db-ppds-withNonfreeDb`) | many PostScript/PCL printers, manufacturer PPDs (Kyocera, Ricoh, Xerox, ...) |
| `gutenprint` | many inkjets (Canon, Epson) |
| `hplip` | HP |
| `brlaser` | Brother monochrome lasers |
| `splix` | Samsung/Xerox SPL |
| `cups-kyodialog`, `cups-kyocera*` | newer Kyocera ECOSYS/TASKalfa (unfree, add to the allowlist) |
| `epson-escpr`, `epson-escpr2` | Epson inkjets |
| `cnijfilter2` | Canon PIXMA |

Search nixpkgs: `nix search nixpkgs cups-` or `nix search nixpkgs <brand>`.

Find the exact PPD inside a package (the path after `share/cups/model/` is the `model` value):

```sh
nix build --no-link --print-out-paths nixpkgs#foomatic-db-ppds
find /nix/store/<hash>-foomatic-db-ppds-*/share/cups/model -iname '*<model>*'
```

After a switch with the driver added, `lpinfo -m | grep -i <model>` lists the same names.

### 5. Choose the device URI

| URI | When |
| --- | --- |
| `ipp://<ip>/ipp/print` | IPP 2.x printers (best: status and job feedback) |
| `socket://<ip>:9100` | raw port 9100; works with almost every network printer |
| `lpd://<ip>/queue` | old printers, LPD |
| `usb://...` | USB, copy from `lpinfo -v` |
| `dnssd://...` | discovered via mDNS, copy from `lpinfo -v` |

Use a fixed IP (in the printer or as a DHCP reservation in the router) or a `.local` name, otherwise the queue breaks when the address changes.

### 6. Make it permanent in Nix

Add the queue to `hardware.printers.ensurePrinters` (see the Kyocera block above), then:

```sh
git add -A          # flakes only see tracked files
nh os switch
lpstat -p -d
lp /etc/os-release  # test page
```

### Alternative: set it up only imperatively (not reproducible)

Works without editing Nix, but is lost on reinstall:

```sh
lpadmin -p MyPrinter -E -v socket://<ip>:9100 -m <model-from-lpinfo-m>
lpadmin -d MyPrinter
```

or click through `system-config-printer` / Plasma System Settings / <http://localhost:631/>. The driver package must still be in `services.printing.drivers`.

### Optional: share the printer with other devices

Phones and other computers can only find this printer if a computer re-announces it. CUPS can do that, but only while the laptop is on:

```nix
services.printing = {
  browsing = true;
  defaultShared = true;
  listenAddresses = [ "*:631" ];
  allowFrom = [ "all" ];
  openFirewall = true;
};
services.avahi.publish = { enable = true; userServices = true; };
```

Not enabled here.

### Scanner (for multifunction devices)

The FS-3820N has none. For a multifunction device: `hardware.sane.enable = true;`, `hardware.sane.extraBackends = [ pkgs.sane-airscan ];` (driverless scanning, or a vendor backend such as `hplipWithPlugin`), add the user to the groups `scanner` and `lp`, and install a scan app such as `simple-scan`.

## Troubleshooting

```sh
systemctl status cups                   # running? queue creation errors show here
journalctl -u cups -e                   # CUPS errors
lpstat -t                               # full status
cupsenable Kyocera_FS-3820N             # re-enable a queue that CUPS stopped after an error
lpinfo -m | grep -i 3820                # is the driver visible?
```

- Job sits in the queue: printer off, wrong IP, or the queue is disabled (`lpstat -p` says "disabled"); run `cupsenable`.
- Garbage or PostScript text printed: wrong driver; use the PostScript PPD of the exact model.
- Printer not found in the GUI scan: expected for this model (no mDNS); it is defined in Nix.
