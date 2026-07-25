<!-- fixed viewBox + preserveAspectRatio="none" so the SVG scales to its container without recomputing coordinates -->
<script lang="ts">
	import type { PlayerHistoryBucket } from '../types';

	let { history, current }: { history: PlayerHistoryBucket[]; current: number } = $props();

	const W = 500;
	const H = 220;
	const PAD = 12;

	function formatTime(unixSeconds: number): string {
		const d = new Date(unixSeconds * 1000);
		return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
	}

	const points = $derived.by(() => [...history, { time: Math.floor(Date.now() / 1000), count: current }]);
	const maxCount = $derived(Math.max(1, ...points.map((p) => p.count)));

	const coords = $derived(
		points.map((p, i) => ({
			x: points.length > 1 ? (i / (points.length - 1)) * (W - PAD * 2) + PAD : W / 2,
			y: H - PAD - (p.count / maxCount) * (H - PAD * 2),
			label: i === points.length - 1 ? 'Now' : formatTime(p.time),
			count: p.count,
		})),
	);

	const linePath = $derived(coords.map((c, i) => `${i === 0 ? 'M' : 'L'}${c.x},${c.y}`).join(' '));
	const areaPath = $derived(
		coords.length > 0 ? `${linePath} L${coords[coords.length - 1].x},${H - PAD} L${coords[0].x},${H - PAD} Z` : '',
	);
</script>

<div class="chart-wrap">
	<svg viewBox="0 0 {W} {H}" preserveAspectRatio="none" class="chart">
		<defs>
			<linearGradient id="areaFill" x1="0" y1="0" x2="0" y2="1">
				<stop offset="0%" stop-color="rgba(139, 92, 246, 0.45)" />
				<stop offset="100%" stop-color="rgba(139, 92, 246, 0)" />
			</linearGradient>
		</defs>
		<path d={areaPath} fill="url(#areaFill)" stroke="none" />
		<path d={linePath} fill="none" stroke="#8b5cf6" stroke-width="2" vector-effect="non-scaling-stroke" />
		{#each coords as c, i (i)}
			<circle cx={c.x} cy={c.y} r="2.5" fill="#b39dff" />
		{/each}
	</svg>
	<div class="labels">
		{#each coords as c, i (i)}
			<span>{c.label}</span>
		{/each}
	</div>
</div>

<style>
	.chart-wrap {
		width: 100%;
		height: 100%;
		display: flex;
		flex-direction: column;
	}

	.chart {
		flex: 1;
		width: 100%;
		min-height: 0;
	}

	.labels {
		display: flex;
		justify-content: space-between;
		padding: 0.4vh 0.6vw 0;
		font-size: 0.85vmin;
		color: var(--color-text-muted);
	}
</style>
