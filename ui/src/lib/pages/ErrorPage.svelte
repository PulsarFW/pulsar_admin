<!-- 404 fallback for the unmatched-route case, navigate() only ever sets known page ids so this is hypothetical -->
<script lang="ts">
	let { code = 404, message = 'Page Not Found' }: { code?: number; subtext?: string; message?: string } = $props();
</script>

<div class="page">
	<h1>{code}</h1>
	<h3>{message}</h3>
</div>

<style>
	.page {
		height: 100%;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		text-align: center;
	}

	h1 {
		font-family: var(--font-heading);
		font-size: 4vmin;
		color: var(--color-text);
		margin: 0;
	}

	h3 {
		font-size: 1.4vmin;
		color: var(--color-text-muted);
		font-weight: 400;
		margin: 0.6vh 0 0;
	}
</style>
