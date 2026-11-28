const escape = String.fromCharCode(27);

const styles = {
	green: "32",
	yellow: "33",
	gray: "90",
	red: "31",
	cyan: "36",
	heading: `1m${escape}[36`,
	sequence: `1m${escape}[35`,
} as const;

type Style = keyof typeof styles;

export function color(message: string, style: Style): string {
	return `${escape}[${styles[style]}m${message}${escape}[0m`;
}

export function log(message: string, style?: Style | "stderr"): void {
	if (style === "stderr") console.error(message);
	else console.log(style ? color(message, style) : message);
}
