import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFileSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { releaseSource, releaseVersion } from "./release-version";

interface Release {
	tag_name: string;
	draft: boolean;
	target_commitish: string;
}

function run(command: string, ...args: string[]): string {
	return execFileSync(command, args, { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] }).trim();
}

function archiveIntegrity(file: string): string {
	return "sha512-" + createHash("sha512").update(readFileSync(file)).digest("base64");
}

async function registry(version: string) {
	const response = await fetch(`https://registry.npmjs.org/@laot%2fbridge/${version}`, { headers: { "cache-control": "no-cache" } });
	if (response.status === 404 && version !== "latest") return undefined;
	if (!response.ok) throw new Error(`npm registry returned ${response.status} for ${version}`);
	const data = (await response.json()) as { version: string; dist: { integrity: string } };
	if (!data.version || !data.dist?.integrity) throw new Error("Invalid npm registry metadata");
	return data;
}

async function publish() {
	const { GITHUB_REPOSITORY: repository, GITHUB_SHA: sha, GITHUB_REF: ref } = process.env;
	if (repository !== "laot7490/ltbridge" || ref !== "refs/heads/main" || !sha || !/^[a-f0-9]{40}$/.test(sha)) {
		throw new Error("Publishing requires the official main branch");
	}
	releaseVersion("11.5.1", run("npm", "--version"));
	const version: string = JSON.parse(readFileSync("package.json", "utf8")).version;
	const tag = `v${version}`;
	const latest = JSON.parse(run("gh", "api", `repos/${repository}/releases/latest`)) as Release;
	if (!latest.tag_name.startsWith("v")) throw new Error("Expected a vX.Y.Z release tag");
	if (!releaseVersion(latest.tag_name.slice(1), version)) return;
	if (run("git", "rev-parse", "HEAD") !== sha) throw new Error("Checkout does not match the tested commit");
	const base = run("git", "rev-parse", `refs/tags/${latest.tag_name}^{commit}`);
	run("git", "merge-base", "--is-ancestor", base, sha);
	if (base === sha) throw new Error("Release requires a new commit");
	const releases = (
		JSON.parse(run("gh", "api", "--paginate", "--slurp", `repos/${repository}/releases?per_page=100`)) as Release[][]
	).flat();
	const draft = releases.find((release) => release.tag_name === tag);
	if (draft && (!draft.draft || !/^[a-f0-9]{40}$/.test(draft.target_commitish))) throw new Error(`Conflicting release ${tag}`);
	const tags = run("git", "tag", "--list", tag);
	const tagSha = tags ? run("git", "rev-parse", `refs/tags/${tag}^{commit}`) : undefined;
	const published = await registry(version);
	const registryLatest = await registry("latest");
	if (!registryLatest) throw new Error("npm has no latest version");
	releaseVersion(registryLatest.version, version);
	const source = releaseSource(sha, tagSha, draft?.target_commitish, !!published);
	const temp = mkdtempSync(path.join(tmpdir(), "ltbridge-release-"));
	const assetName = `ltbridge-${tag}.tar.gz`;
	const asset = path.join(temp, assetName);

	try {
		if (published) {
			run("git", "merge-base", "--is-ancestor", base, source);
			run("git", "merge-base", "--is-ancestor", source, sha);
			const sourceVersion = JSON.parse(run("git", "show", `${source}:package.json`)).version;
			if (sourceVersion !== version) throw new Error("Draft commit has a different package version");
			run("gh", "release", "download", tag, "--pattern", assetName, "--dir", temp);
			if (archiveIntegrity(asset) !== published.dist.integrity)
				throw new Error("Draft archive does not match the published npm package");
		} else {
			run("npm", "run", "build");
			run("npm", "pack", "--ignore-scripts", "--pack-destination", temp);
			const archives = readdirSync(temp).filter((name) => name.endsWith(".tgz"));
			if (archives.length !== 1) throw new Error("Expected exactly one npm tarball");
			const tarball = path.join(temp, archives[0]);
			copyFileSync(tarball, asset);
			const notes = path.join(temp, "notes.md");
			const changes = run("git-cliff", "--config", "cliff.toml", "--tag-pattern", "^$", `${base}..${sha}`);
			const comparison = `${latest.tag_name}...${tag}`;
			writeFileSync(notes, `${changes}\n\n**Full Changelog:** [\`${comparison}\`](https://github.com/${repository}/compare/${comparison})\n`);
			if (draft) {
				run("gh", "release", "edit", tag, "--target", sha, "--notes-file", notes);
				run("gh", "release", "upload", tag, asset, "--clobber");
			} else {
				run("gh", "release", "create", tag, asset, "--draft", "--title", tag, "--target", sha, "--notes-file", notes);
			}
			console.log(run("npm", "publish", tarball, "--access", "public", "--ignore-scripts"));
		}
		console.log(run("gh", "release", "edit", tag, "--draft=false", "--latest"));
	} finally {
		rmSync(temp, { recursive: true, force: true });
	}
}

publish().catch((error: unknown) => {
	console.error(error instanceof Error ? error.message : error);
	process.exitCode = 1;
});
