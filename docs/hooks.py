import posixpath
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit, urlunsplit

from markdown.extensions import Extension
from markdown.treeprocessors import Treeprocessor
from mkdocs.exceptions import PluginError
from mkdocs.structure.files import File


SOURCE_DIRECTORIES = (
    "AdvancedHunting",
    "AzATP_Lab",
    "Defender",
    "Federation",
    "Linux",
    "LiveResponse",
    "MDELab",
    "MDILab",
    "OceanLotus",
)
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}
DOWNLOAD_EXTENSIONS = {".ps1", ".py", ".json", ".yml", ".yaml", ".sls", ".zip"}
PAGE_ALIASES = {
    "MDELab/Attacks.md": "MDELab/Attacks/README.md",
    "MDILab/Attacks.md": "MDILab/Attacks/README.md",
    "MDILab/Attacks/SmbSessionEnumeration.md": "MDILab/Attacks/NetSessionEnumeration.md",
}


class RepositoryLinks(Treeprocessor):
    def __init__(self, md, links):
        super().__init__(md)
        self.links = links

    def run(self, root):
        for element in root.iter():
            attribute = {"a": "href", "img": "src"}.get(element.tag)
            if attribute and attribute in element.attrib:
                element.set(attribute, self.links.resolve(element.get(attribute)))


class RepositoryLinksExtension(Extension):
    def __init__(self, root, repo_url):
        self.root = root
        self.repo_url = repo_url.rstrip("/")
        self.source = None
        self.source_uri = None
        self.pages = {}
        super().__init__()

    def extendMarkdown(self, md):
        md.treeprocessors.register(RepositoryLinks(md, self), "repository_links", 10)

    def resolve(self, href):
        url = urlsplit(href)
        if url.scheme or url.netloc or not url.path:
            return href
        if url.path.startswith("/"):
            raise PluginError(f"{self.source}: use a relative repository link, not {href!r}")

        target = (self.source.parent / unquote(url.path)).resolve()
        if not target.is_relative_to(self.root) or not target.exists():
            raise PluginError(f"{self.source}: local link target does not exist: {href!r}")

        if target.is_dir() and (target / "README.md").is_file():
            target = target / "README.md"
        if target.suffix.lower() == ".md" or target.suffix.lower() in IMAGE_EXTENSIONS:
            if target not in self.pages:
                raise PluginError(f"{self.source}: documentation target is not included: {href!r}")
            destination = posixpath.relpath(
                self.pages[target], posixpath.dirname(self.source_uri) or "."
            )
            return urlunsplit(("", "", quote(destination), url.query, url.fragment))

        relative = quote(target.relative_to(self.root).as_posix())
        if target.is_dir():
            destination = f"{self.repo_url}/tree/master/{relative}"
        elif target.suffix.lower() in DOWNLOAD_EXTENSIONS:
            destination = f"https://raw.githubusercontent.com/dmcwee/labs/refs/heads/master/{relative}"
        else:
            destination = f"{self.repo_url}/blob/master/{relative}"
        return urlunsplit((*urlsplit(destination)[:3], url.query, url.fragment))


def on_config(config):
    root = Path(config.config_file_path).resolve().parent
    extension = RepositoryLinksExtension(root, config.repo_url)
    config.markdown_extensions.append(extension)
    config.watch.extend(str(root / path) for path in ("README.md", *SOURCE_DIRECTORIES))
    return config


def on_files(files, config):
    root = Path(config.config_file_path).resolve().parent
    sources = [root / "README.md"]
    for directory in SOURCE_DIRECTORIES:
        sources.extend(
            path
            for path in sorted((root / directory).rglob("*"))
            if path.is_file()
            and (path.suffix.lower() == ".md" or path.suffix.lower() in IMAGE_EXTENSIONS)
        )
    for path in sources:
        if path.relative_to(root).as_posix() in PAGE_ALIASES:
            continue
        files.append(
            File(
                path.relative_to(root).as_posix(),
                str(root),
                config.site_dir,
                config.use_directory_urls,
            )
        )
    destinations = {}
    for file in files:
        if file.dest_uri in destinations:
            raise PluginError(
                f"Site route collision: {destinations[file.dest_uri]} and {file.src_uri}"
            )
        destinations[file.dest_uri] = file.src_uri
        if file.abs_src_path and Path(file.abs_src_path).is_relative_to(root):
            file.edit_uri = Path(file.abs_src_path).relative_to(root).as_posix()
    for extension in config.markdown_extensions:
        if isinstance(extension, RepositoryLinksExtension):
            extension.pages = {
                Path(file.abs_src_path).resolve(): file.src_uri
                for file in files
                if file.abs_src_path
            }
            for alias, canonical in PAGE_ALIASES.items():
                extension.pages[root / alias] = extension.pages[root / canonical]
    return files


def on_page_markdown(markdown, page, config, files):
    for extension in config.markdown_extensions:
        if isinstance(extension, RepositoryLinksExtension):
            extension.source = Path(page.file.abs_src_path).resolve()
            extension.source_uri = page.file.src_uri
    return markdown
