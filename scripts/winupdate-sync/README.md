# Offline Windows Update repository

Syncs an offline repository of Windows Server Cumulative Updates (LCU) and
Servicing Stack Updates (SSU) from the Microsoft Update Catalog to NFS-backed
storage, and serves it over HTTP for Packer Windows builds to consume instead
of hitting Microsoft Update live during provisioning.

## Sync

`sync.ps1` runs on a schedule via the `sync_windows_updates` CI job
(`.gitlab-ci.yml`), triggered by a dedicated GitLab Pipeline Schedule with
`SYNC_WINDOWS_UPDATES=true` set.

Per product (see `config.psd1`), it:

1. Queries the Microsoft Update Catalog (via the `MSCatalogLTS` PowerShell
   module) for the LCU and SSU matching that product's search text, filtered
   to `CutoffDate` onward, and keeps the latest `RetentionCount` releases.
2. Diffs that desired set against the remote `manifest.json` to find what's
   new and what's fallen out of the retention window.
3. Prunes obsolete files first (over SSH), then downloads and pushes new
   files one at a time — each item is downloaded, `rsync`'d up, and dropped
   locally before moving to the next, and `manifest.json` is rewritten after
   every step. This bounds local disk use to one update at a time and makes
   a mid-run failure resumable: the next run picks up wherever the last one
   left off, rather than re-downloading everything.

Transport is `rsync` over SSH (`WINUPDATE_REPO_HOST`/`_USER`/`_PATH` env
vars, populated from masked project CI/CD variables — see the
`sync_windows_updates` job for the exact variable names). Set
`WINUPDATE_SSH_DEBUG=true` on the job temporarily to get verbose `ssh`/
`rsync` auth negotiation output in the log when diagnosing a connection
problem.

### Repository layout

```
<repoPath>/
├── manifest.json                     # authoritative index of what's present
└── <product>/<arch>/<Kind>_<KB>/     # e.g. win2022/x64/Lcu_KB5099540/
    └── *.msu / *.cab                 # one or more files per update
```

## Serving (DSM Web Station)

The repo lives on a Synology NAS share (`/volume1/winupdate`) and is served
over plain HTTP using DSM's built-in **Web Station**, which runs Nginx as its
HTTP back-end:

1. **Package Center** → install **Web Station**.
2. **Web Station → Web Service → Create** → backend **Nginx**.
3. **Web Station → Virtual Host → Create**:
   - Hostname: `winupdate.mpoore.cloud`
   - Port: internal-only HTTP port (not DSM's 5000/5001 admin ports)
   - Document root: the shared folder backing the sync job's `repoPath`
     (`/volume1/winupdate`)
   - Backend server: the Nginx Web Service from step 2
4. Optional directory listing (not required — consumers can fetch
   `manifest.json` and hit exact file URLs directly): add to the virtual
   host's extra/custom Nginx configuration —
   ```nginx
   autoindex on;
   autoindex_exact_size off;
   autoindex_localtime on;
   ```

**Access**: this serves real Windows Server update binaries unauthenticated.
Nothing secret, but the virtual host should stay on the internal network only
— not exposed via DSM's reverse proxy or QuickConnect to the internet.

### Two Synology gotchas hit while setting this up

- **DSM gates `rsync` separately from SSH.** A user can have full SSH/shell
  access and still get `Permission denied, please try again.` specifically
  from `rsync --server`, because DSM checks the user's Applications
  permission and whether the `rsync` service itself is enabled
  (**Control Panel → File Services → rsync**, and
  **Control Panel → User & Group → *user* → Applications**) independently of
  general SSH access and of the target directory's actual filesystem
  permissions.
- **`rsync` only creates the final path component on the remote side.** It
  won't create a full chain of missing parent directories, so `sync.ps1`
  explicitly `mkdir -p`s each item's target directory over SSH before
  pushing to it (see `New-RemoteDirectory` in `sync.ps1`).

## Manifest format

`manifest.json` is a flat JSON array; each entry:

```json
{
  "Product": "win2022",
  "Arch": "x64",
  "Kind": "Lcu",
  "Kb": "KB5099540",
  "Title": "...",
  "Guid": "...",
  "LastUpdated": "...",
  "RelativePath": "win2022/x64/Lcu_KB5099540"
}
```

A consumer (e.g. a future `scripts/windows/setup.ps1` offline-update mode)
fetches `http://winupdate.mpoore.cloud/manifest.json`, filters to its own
product/arch, and downloads the files under each entry's `RelativePath`.
