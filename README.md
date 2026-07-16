# packer

Automated, repeatable **Packer** build definitions for producing golden VM templates and images on **VMware vSphere**.

Every build in this repository starts from vendor-supplied installation media, drives an unattended OS installation, applies configuration via [Salt](https://saltproject.io/) states, and publishes the result as a vCenter template (and, optionally, to a vSphere Content Library) — ready to be consumed by downstream automation.

---

## What's in here

Builds are organised by platform and operating system under [`vsphere/`](vsphere/):

```
vsphere/
├── vsphere.pkrvars.example.hcl   # Template for environment-specific variables
├── esx/                          # VMware ESX builds
│   └── esx8/
├── linux/                        # Linux distribution builds
│   ├── centos9/
│   ├── centos10/
│   ├── photon5/
│   ├── rhel9/
│   ├── rhel10/
│   ├── rocky9/
│   ├── rocky10/
│   ├── ubuntu2204/
│   ├── ubuntu2404/
│   └── ubuntu2604/
├── windows/                       # Windows Server builds
│   ├── win2019/
│   ├── win2022/
│   └── win2025/
└── archive/                       # Retired/superseded builds, kept for reference
```

Each build directory is self-contained and typically includes:

| File | Purpose |
|---|---|
| `<name>.pkr.hcl` | The Packer build definition — the `vsphere-iso` source, the `build` block, provisioners and post-processors. |
| `vars.pkr.hcl` | Declares every variable the build accepts (vCenter connection details, VM hardware, OS customisation, timeouts, etc.), each with a sensible default. |
| `<name>.auto.pkrvars.hcl` | OS-specific defaults that are automatically loaded by Packer (ISO name/path, OS metadata, hardware sizing) — these are what make each build distinct from the others. |
| `cfg/` or `data/` | Templated answer files used to drive the unattended install — Kickstart (`ks.pkrtpl.hcl`) for RHEL-family distros, cloud-init (`user-data.pkrtpl.hcl`) for Ubuntu, or Windows `Autounattend.xml`. |

All builds share the same overall pattern:

1. **Boot** a VM in vSphere from an OS ISO, injecting an answer file (Kickstart, cloud-init or Autounattend) via a virtual CD/floppy.
2. **Install** the OS unattended, creating a build-time administrative user.
3. **Provision** the machine using the `salt` Packer plugin, applying a Salt state tree and pillar data to bring the OS to its final configured state (patching, hardening, agent installation, etc.).
4. **Publish** the result as a vCenter template — and, on release branches, export it to a vSphere Content Library.
5. **Record** the build in a manifest file (see [`manifests/`](manifests/)) containing version, build date, branch and source ISO details, for traceability.

CI (see [`.gitlab-ci.yml`](.gitlab-ci.yml)) automatically discovers build directories under `vsphere/*/*` and runs `packer build` for whichever ones changed on a push, or for all of them on a scheduled pipeline — so adding a new OS build is as simple as adding a new directory, no pipeline editing required. The pipeline runs in a container image built from [packer-ci](https://github.com/mpoore/packer-ci), which bundles Packer, the required plugins and supporting tooling needed to run these builds.

Supporting directories:

- [`salt/`](salt/) — the Salt state tree and pillar data applied by every build's `salt` provisioner.
- [`scripts/`](scripts/) — helper shell/PowerShell scripts used by specific builds (e.g. ESXi and Windows).
- [`scripts/winupdate-sync/`](scripts/winupdate-sync/) — CI-scheduled tool that syncs an offline repository of Windows Server Cumulative/Servicing Stack Updates to NFS-backed storage, pruning anything outside the configured retention window (see [`sync_windows_updates`](.gitlab-ci.yml) job).
- [`manifests/`](manifests/) — output location for Packer manifest files produced by each build.
- [`logs/`](logs/) — output location for build logs when logging is enabled (see below).

## The Salt Packer plugin

Configuration management inside these builds is handled by **[packer-plugin-salt](https://github.com/mpoore/packer-plugin-salt)** — a Packer plugin that applies a masterless Salt state tree and pillar data directly during the build, with no external Salt master required.

Every modern Linux and Windows build declares it as a required plugin and uses it in the `build` block, for example:

```hcl
packer {
    required_plugins {
        salt = {
            version = ">= 0.5.7"
            source  = "github.com/mpoore/salt"
        }
    }
}

build {
    provisioner "salt" {
        state_tree  = var.state_tree
        pillar_tree = var.pillar_tree
    }
}
```

See the [plugin repository](https://github.com/mpoore/packer-plugin-salt) for full documentation of its configuration options.

## Setting up your own variables

Connection details, credentials and environment-specific settings (vCenter server, datastore, network, credentials, PKI, etc.) are kept out of version control and supplied via a single shared variables file.

A template is provided at [`vsphere/vsphere.pkrvars.example.hcl`](vsphere/vsphere.pkrvars.example.hcl). To use it:

1. Copy the example file, dropping `.example` from the name:

   ```bash
   cp vsphere/vsphere.pkrvars.example.hcl vsphere/vsphere.pkrvars.hcl
   ```

2. Edit `vsphere/vsphere.pkrvars.hcl` and replace the placeholder values with your own environment's details — vCenter server, credentials, datacenter, cluster, datastore, network, content library, and PKI certificate URLs.

3. Leave it in place. `vsphere/vsphere.pkrvars.hcl` is already listed in [`.gitignore`](.gitignore) so it will never be committed — it's for local/CI use only, passed to `packer build` with `-var-file`.

Each individual build also has its own `vars.pkr.hcl` (documenting every available variable and its default) and `<name>.auto.pkrvars.hcl` (OS-specific defaults such as ISO name/path and hardware sizing), which you can override on the command line with additional `-var` or `-var-file` arguments if needed.

## Running a build

With `vsphere/vsphere.pkrvars.hcl` in place, invoke Packer from the repository root, pointing it at the shared variable file and the build directory you want:

**Detailed logging** — full Packer debug logging written to a file, useful when diagnosing a failing build:

```bash
PACKER_LOG=1 PACKER_LOG_PATH="logs/centos10.ans" packer build -var-file=vsphere/vsphere.pkrvars.hcl vsphere/linux/centos10
```

**Light logging** — plain, colourless console output with timestamps, saved to a log file while still visible in the terminal:

```bash
packer build -color=false -timestamp-ui -var-file=vsphere/vsphere.pkrvars.hcl vsphere/linux/centos10 | tee logs/centos10.log
```

**Console messages only** — a quick interactive run with no logging, aborting immediately on the first error:

```bash
packer build -on-error=abort -var-file=vsphere/vsphere.pkrvars.hcl vsphere/linux/centos10
```

Substitute `vsphere/linux/centos10` for any other build directory (e.g. `vsphere/windows/win2022`, `vsphere/esx/esx8`) to run that build instead.

## License

This project is licensed under the **[GNU General Public License v3.0](LICENSE)**.

In short: you're free to use, study, share and modify this code, including for commercial purposes — but if you distribute your own version (modified or not), you must make the source code available under the same GPLv3 terms and preserve the original copyright and license notices. There is no warranty provided.