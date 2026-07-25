<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import Chart from '../primitives/Chart.svelte';
	import type { PlayerHistory } from '../types';

	let data = $state<PlayerHistory>({ current: 0, max: 64, queue: 0, history: [] });

	onMount(async () => {
		const res = await Nui.getPlayerHistory();
		if (res) data = res;
	});

	const pct = $derived(data.max > 0 ? Math.floor((data.current / data.max) * 100) : 0);
</script>

<div class="page">
	<div class="stats">
		<div class="stat">
			<span class="label">Online Players</span>
			<span class="value">{data.current}</span>
		</div>
		<div class="stat">
			<span class="label">Players in Queue</span>
			<span class="value">{data.queue}</span>
		</div>
		<div class="track"><div class="fill" style:width="{pct}%"></div></div>
	</div>

	<div class="chart-card">
		<Chart history={data.history} current={data.current} />
	</div>
</div>

<style>
	.page {
		padding: 2vh 1.5vw;
		height: 100%;
		display: flex;
		flex-direction: column;
		gap: 2vh;
	}

	.stats {
		background: rgba(232, 232, 236, 0.03);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 1.6vh 1.4vw;
	}

	.stat {
		display: inline-flex;
		flex-direction: column;
		margin-right: 4vw;
	}

	.label {
		font-size: 0.9vmin;
		color: var(--color-text-muted);
	}

	.value {
		font-size: 1.8vmin;
		font-weight: 700;
		color: var(--color-text);
	}

	.track {
		margin-top: 1.4vh;
		height: 4px;
		background: rgba(232, 232, 236, 0.1);
		border-radius: 2px;
		overflow: hidden;
	}

	.fill {
		height: 100%;
		background: var(--color-primary);
		transition: width 200ms ease;
	}

	.chart-card {
		flex: 1;
		min-height: 0;
		background: rgba(232, 232, 236, 0.03);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 1.6vh 1.4vw;
	}
</style>
