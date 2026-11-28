export function releaseVersion(before: string, after: string): string | undefined {
	const stable = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
	if (!stable.test(before) || !stable.test(after)) throw new Error("Expected stable X.Y.Z versions");
	const previous = before.split(".").map(BigInt);
	const candidate = after.split(".").map(BigInt);
	const difference = candidate.findIndex((part, index) => part !== previous[index]);
	if (difference === -1) return undefined;
	if (candidate[difference] < previous[difference]) throw new Error("Release version must increase");
	return after;
}

export function releaseSource(
	currentSha: string,
	tagSha: string | undefined,
	draftSha: string | undefined,
	published: boolean,
): string {
	if (published && !draftSha) throw new Error("Published package needs a matching release draft");
	if (!published && draftSha && draftSha !== currentSha) throw new Error("Pending draft belongs to another commit");
	const source = draftSha ?? currentSha;
	if (tagSha && tagSha !== source) throw new Error("Release tag points to another commit");
	return source;
}
