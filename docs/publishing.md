# Documentation preview and publishing

The repository README and existing Markdown guides are the authoritative content.
MkDocs renders those same files without moving lab folders or maintaining a second
copy of the scenario instructions. The root README becomes the site home page.

## Preview locally

From the repository root, create a virtual environment and install the documentation dependencies:

```powershell
python -m venv .venv-docs
.\.venv-docs\Scripts\python.exe -m pip install -r requirements-docs.txt
.\.venv-docs\Scripts\python.exe -m unittest discover -s tests\documentation
.\.venv-docs\Scripts\python.exe -m mkdocs build --strict
.\.venv-docs\Scripts\python.exe -m mkdocs serve
```

Open the address printed by MkDocs, including its `/labs/` path. On Linux or macOS,
use `.venv-docs/bin/python` in place of the Windows virtual-environment executable.
Generated output in `site` and the virtual environment are ignored by Git.
Restart `mkdocs serve` after changing the Python hook; edits to Markdown guides
are watched and rebuilt automatically.

## Add or edit a guide

Edit existing Markdown beside its related lab or scenario. Add general
documentation under `docs` and navigation entries in `mkdocs.yml`. New guides in
the existing source directories are included by `docs/hooks.py`; adding a new
top-level lab directory also requires updating `SOURCE_DIRECTORIES` in that hook.

Use ordinary Markdown links relative to the source file. The hook keeps the
repository directory structure in MkDocs, resolves links to directory READMEs,
and turns local script links into raw GitHub downloads. It rejects missing local
targets. Keep prerequisites, warnings, and cleanup in the guide itself so readers
can use either GitHub or the rendered website. Do not put secrets or private
configuration into documentation or linked assets.

Deployable lab landing pages use the same six sections: **Quick Deploy**,
**Deployment parameters**, **Deployed machines**, **Network and access**,
**Post-deployment configuration**, and **Next steps**. Keep parameter defaults,
machine names, image SKUs, and private IPs aligned with the linked Bicep entrypoint.
Describe legacy ARM contracts separately rather than mixing them with the Bicep
tables. Moved or reference-only folders should state their status instead of
inventing deployment parameters. Update the documentation inventory checks when
intentionally changing a lab's machines.

Each Quick Deploy section must include a CLI command using `--template-uri` and
a Deploy to Azure button whose decoded URL selects that exact same published
template. Do not pair local Bicep compilation with a different published artifact.
Update both together and record source/publication differences in the
[deployment alignment guide](deployment-alignment.md).

Scenario overviews use **Deployment context**, **Accounts and sign-in**,
**Machines and roles**, **Before running a scenario**, **Scenarios**, and
**Cleanup** sections. Keep their inventories aligned with the landing page and
Bicep, including requested computer names and private IPs. Document `username`
defaults honestly, derive hydrated users and groups from `DcHydrate.ps1`, and
distinguish those identities from temporary script-created accounts. Never add
deployment passwords to examples. Individual MDE/MDI guides link back to their
lab context and use its domain/controller names rather than unrelated sample
environments. If no walkthrough exists, state that explicitly instead of implying
that another lab's scripts work unchanged.

Active individual MDE/MDI walkthroughs use these sections in order:
**Overview**, **MITRE ATT&CK Mapping**, **Attack Simulation**, **Setup**,
**Scenario Execution**, **Expected Alerts**, **Why Does This Matter**,
**Best Practices**, and **Clean-Up**. Put optional **Manual Commands** after
cleanup and **References** last. Group supplementary detection tables within
Expected Alerts rather than creating a second top-level detection section.
Preserve old heading anchors when renaming or moving linked sections.

Script parameter tables use **Parameter**, **Type**, **Required**, **Default**,
and **Description**, with a leading hyphen on parameter names. Required means
mandatory to PowerShell, not a suggested lab override or a conditional
prerequisite; explain those separately. Use **Not set** for unset values and
switch defaults. Manual walkthroughs such as Account Advanced Hunting keep the
same section layout but do not need an invented script parameter table.
The retained SMB source page is a compatibility alias, not an active walkthrough
to normalize separately.

The existing `MDELab/Attacks.md` and `MDILab/Attacks.md` entry pages remain in the
repository. For the site, `PAGE_ALIASES` maps their links to the full scenario
indexes instead of publishing duplicate pages at the same URLs. The build rejects
other output-route collisions, which would otherwise overwrite pages and corrupt
the search index.

The retained SMB session enumeration page is also treated as an alias for the
Net Session Enumeration guide, so it does not produce a second site/search page.

The documentation workflow runs for all pull requests and pushes to `master`.
This deliberately avoids missing documentation changes in existing lab folders.
PRs build and validate only; they do not deploy, execute scenario scripts, or
provision Azure resources.

## Publish at the project subpath

The canonical site URL is **https://davidmcwee.com/labs/**. The `/labs/` base path
is configured in `mkdocs.yml`; use relative internal links rather than links
starting with `/`. MkDocs generates navigation, assets, canonical links, search,
and sitemap URLs for this project path.

The user/organization Pages site already owns `davidmcwee.com`. This project
inherits that domain at `/labs/`: do not add a project `CNAME`, configure a project
custom domain, change DNS, or modify the root-domain repository.

To enable the initial publication, a repository administrator must:

1. Open this repository's **Settings > Pages** and select **GitHub Actions** as
   the build and deployment source. Leave the project's custom-domain setting unset.
2. Merge the documentation changes into `master`. The dedicated documentation
   workflow builds and deploys a Pages artifact using the `github-pages` environment.
3. Check any environment protection approvals and confirm that the site is
   reachable at `https://davidmcwee.com/labs/`, including a nested scenario page,
   search, and downloadable script links.

The workflow can also be dispatched manually from `master`. Dispatches on other
branches build but do not deploy. Pages permissions are confined to the deployment
job; production deployments are serialized. No `gh-pages` branch is required.

## Keep deployment publishing separate

The existing Bicep workflow and `published` branch continue to supply ARM templates
and provisioning assets. Documentation entry points select the same published
artifact for CLI and portal use; the Linux button was intentionally updated to
the two-VM published template. Website publication does not rebuild infrastructure
artifacts, change runtime script channels, or imply a lab deployment has been verified.

The Bicep publisher watches shared modules as well as lab templates and checks
compiled gateway SKUs before publishing. Pushes or manual runs on `master` update
`published/pub`; runs on `dev` update `published/dev`. Apply source fixes to both
branches when both channels need refreshing. The publisher serializes both
channels because they write to the same branch; Pages publishing stays separate.
